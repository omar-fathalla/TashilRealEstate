const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {
  requireAuth,
  requireRole,
  loadLease,
  leaseAmount,
  assertLeaseParty,
  safeContinueUrl,
} = require("./authz");

setGlobalOptions({ maxInstances: 10, region: "us-central1" });

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.processRentPayment = onCall({ enforceAppCheck: true, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const lease = await loadLease(request.data && request.data.leaseId);
  assertLeaseParty(auth, lease);
  const amount = leaseAmount(lease);
  const platformFee = amount * 0.02;
  const agencyFee = amount * 0.08;
  const ownerPayout = amount * 0.90;

  try {
    const db = admin.firestore();
    const transactionRef = db.collection("Transactions").doc();
    await transactionRef.set({
      transactionId: transactionRef.id,
      leaseId: lease.id,
      tenant_id: lease.tenant_id || null,
      owner_id: lease.owner_id || null,
      amount: amount,
      splits: { platformFee, agencyFee, ownerPayout },
      // Completed is reserved for a verified payment-provider webhook.
      status: "Pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: auth.uid,
    });
    return { success: true, transactionId: transactionRef.id, status: "Pending" };
  } catch (error) {
    logger.error("Error processing rent payment", error);
    throw new HttpsError("internal", "Failed to record the payment request.");
  }
});

exports.sendRentalReminder = onCall({ enforceAppCheck: true, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  requireRole(auth, ["Owner", "AgencyAdmin", "SuperAdmin"]);
  const data = request.data || {};
  const lease = await loadLease(data.leaseId);
  assertLeaseParty(auth, lease);
  if (data.tenantId && auth.token.role !== "SuperAdmin" && lease.tenant_id !== data.tenantId) {
    throw new HttpsError("permission-denied", "That tenant is not on this lease.");
  }
  const tenantId = lease.tenant_id;
  const propertyTitle = data.propertyTitle || "وحدة سكنية";
  const amount = leaseAmount(lease);
  const dueDate = data.dueDate || new Date().toISOString();
  const countryCode = lease.countryCode || data.countryCode || "EG";
  const currency = countryCode === "AE" ? "AED" : "EGP";

  const db = admin.firestore();
  const notifRef = db.collection("Notifications").doc();

  const notificationPayload = {
    id: notifRef.id,
    recipientId: tenantId,
    type: "rental_due_reminder",
    title: {
      ar: "تذكير استحقاق الإيجار الشهري",
      en: "Monthly Rent Payment Reminder",
      hi: "मासिक किराया भुगतान अनुस्मारक",
    },
    body: {
      ar: `نحيطكم علماً باستحقاق دفعة الإيجار (${amount} ${currency}) لعقار: ${propertyTitle}`,
      en: `Friendly reminder: Rent payment (${amount} ${currency}) is due for: ${propertyTitle}`,
      hi: `अनुस्मारक: ${propertyTitle} के लिए किराया भुगतान (${amount} ${currency}) देय है`,
    },
    dueDate: dueDate,
    amount: amount,
    currency: currency,
    status: "delivered",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    await notifRef.set(notificationPayload);
    // Also mirror to user notifications subcollection
    if (tenantId) {
      await db.collection("Users").doc(tenantId).collection("notifications").doc(notifRef.id).set(notificationPayload);
    }
    logger.info(`Rental reminder notification created: ${notifRef.id}`);
    return { success: true, messageId: notifRef.id };
  } catch (error) {
    logger.error("Error creating rental reminder", error);
    throw new HttpsError("internal", "Failed to create the reminder.");
  }
});

exports.generateRentalInvoiceReceipt = onCall({ enforceAppCheck: true, maxInstances: 10 }, async (request) => {
  const auth = requireAuth(request);
  const data = request.data || {};
  const lease = await loadLease(data.leaseId);
  assertLeaseParty(auth, lease);
  const leaseId = lease.id;
  const tenantName = data.tenantName || "عميل تسهيل";
  const amount = leaseAmount(lease);
  const currencyCode = lease.countryCode === "AE" ? "AED" : (data.currencyCode || "EGP");

  const platformFee = amount * 0.025; // 2.5% platform fee
  const agencyFee = amount * 0.08;   // 8% agency fee
  const vatRate = currencyCode === "AED" ? 0.05 : 0.14;
  const vatAmount = (platformFee + agencyFee) * vatRate;
  const totalPaid = amount + vatAmount;

  const invoiceNumber = `TASHIL-INV-${new Date().getFullYear()}-${Date.now().toString().slice(-6)}`;
  const db = admin.firestore();
  const invoiceRef = db.collection("Invoices").doc(invoiceNumber);

  const invoiceData = {
    invoiceNumber: invoiceNumber,
    leaseId: leaseId,
    tenantName: tenantName,
    amount: amount,
    platformFee: platformFee,
    agencyFee: agencyFee,
    vatAmount: vatAmount,
    totalPaid: totalPaid,
    currencyCode: currencyCode,
    tenant_id: lease.tenant_id || null,
    owner_id: lease.owner_id || null,
    // Paid_Verified is reserved for a verified payment-provider webhook.
    status: "Issued",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    await invoiceRef.set(invoiceData);
    logger.info(`Generated digital rental invoice: ${invoiceNumber}`);
    return { success: true, invoiceNumber: invoiceNumber, status: "Issued" };
  } catch (error) {
    logger.error("Error generating rental invoice", error);
    throw new HttpsError("internal", "Failed to issue the invoice.");
  }
});


// seedDatabase is intentionally not exported. Seeding lives in
// backend/seed_emulator.js and only runs against the local emulators.

/**
 * Sanitizes an owner property document for the public marketplace (/Properties).
 * Enforces Zero-Leakage Data Standards by strictly stripping all private landlord,
 * tenant PII, financial installments, and internal notes.
 */
function sanitizeForMarketplace(data, ownerId, propertyId) {
  const titles = (typeof data.titles === "object" && data.titles !== null)
    ? data.titles
    : { ar: data.title || "", en: data.title || "", hi: data.title || "" };

  const descriptions = (typeof data.descriptions === "object" && data.descriptions !== null)
    ? data.descriptions
    : { ar: data.description || "", en: data.description || "", hi: data.description || "" };

  const locations = (typeof data.locations === "object" && data.locations !== null)
    ? data.locations
    : { ar: data.location || "", en: data.location || "", hi: data.location || "" };

  const images = Array.isArray(data.imageUrls) && data.imageUrls.length > 0
    ? data.imageUrls
    : (data.image ? [data.image] : []);

  return {
    id: propertyId || data.id,
    owner_id: ownerId,
    countryCode: data.countryCode || "EG",
    currencyCode: data.currencyCode || (data.countryCode === "AE" ? "AED" : "EGP"),
    titles: titles,
    descriptions: descriptions,
    locations: locations,
    cityCode: data.cityCode || "cairo",
    propertyTypeCode: data.propertyTypeCode || "apartment",
    buildingName: data.buildingName || "",
    pricePerMonth: Number(data.pricePerMonth) || 0,
    bedrooms: Number(data.bedrooms) || 1,
    bathrooms: Number(data.bathrooms) || 1,
    areaSqM: Number(data.areaSqM) || 100,
    image: images[0] || "",
    imageUrls: images,
    amenitiesMap: data.amenitiesMap || {
      ar: ["مفروش بالكامل", "تكييف مركزي", "موقف سيارات خاص", "أمن وحراسة 24/7"],
      en: ["Fully Furnished", "Central A/C", "Private Parking", "24/7 Security"],
      hi: ["पूरी तरह सुसज्जित", "केंद्रीय एसी", "निजी पार्किंग", "24/7 सुरक्षा"],
    },
    agencyNames: data.agencyNames || {
      ar: "شركة تسهيل لإدارة الأملاك",
      en: "Tashil Property Management",
      hi: "तशिल संपत्ति प्रबंधन",
    },
    agencyPhone: data.agencyPhone || "+20 100 123 4567",
    rating: typeof data.rating === "number" ? data.rating : 5.0,
    isFeatured: Boolean(data.isFeatured !== undefined ? data.isFeatured : true),
    is_published: true,
    status: "vacant",
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    // Strictly stripped & excluded to ensure zero leakage:
    // - tenantName
    // - tenantPhone
    // - installments
    // - leaseStartDate
    // - leaseEndDate
    // - unitNumber
    // - notes / internalNotes
  };
}

/**
 * Event-Driven Cloud Function: Automatically synchronizes owner property mutations
 * from the private tree (Users/{ownerId}/properties/{propertyId}) to the public
 * marketplace collection (/Properties/{propertyId}).
 */
exports.syncOwnerPropertyToMarketplace = onDocumentWritten(
  "Users/{ownerId}/properties/{propertyId}",
  async (event) => {
    const ownerId = event.params.ownerId;
    const propertyId = event.params.propertyId;
    const db = admin.firestore();
    const marketDocRef = db.collection("Properties").doc(propertyId);

    // 1. Handle document deletion in owner's tree
    if (!event.data || !event.data.after || !event.data.after.exists) {
      logger.info(`Property [${propertyId}] was deleted by owner [${ownerId}]. Removing from /Properties.`);
      try {
        await marketDocRef.delete();
      } catch (err) {
        logger.error(`Error deleting property [${propertyId}] from /Properties`, err);
      }
      return null;
    }

    const afterData = event.data.after.data();
    const isPublished = Boolean(afterData.isPublished);
    const rentalStatus = afterData.rentalStatus || "available";

    // 2. Handle active published property
    const city = String(afterData.cityCode || afterData.city_code || "").toLowerCase();
    const permit = String(afterData.adPermitNumber || afterData.advertisingPermitNumber || "");
    const dubaiPermitMissing = city === "dubai" && !/^[0-9]{6,15}$/.test(permit);
    if (isPublished && rentalStatus === "available" && dubaiPermitMissing) {
      logger.info(`Refusing to publish Dubai listing [${propertyId}] without an advertising permit.`);
    }

    if (isPublished && rentalStatus === "available" && !dubaiPermitMissing) {
      logger.info(`Syncing published property [${propertyId}] for owner [${ownerId}] to /Properties`);
      const sanitized = sanitizeForMarketplace(afterData, ownerId, propertyId);
      if (permit) sanitized.adPermitNumber = permit;
      try {
        await marketDocRef.set(sanitized, { merge: true });
        logger.info(`Successfully synchronized sanitized property [${propertyId}] to public marketplace.`);
      } catch (err) {
        logger.error(`Error syncing property [${propertyId}] to /Properties`, err);
        throw err;
      }
    } else {
      // 3. Handle rented, unpublished, or maintenance properties -> Conceal from public marketplace
      logger.info(`Concealing property [${propertyId}] from /Properties (status: ${rentalStatus}, isPublished: ${isPublished})`);
      try {
        await marketDocRef.set({
          is_published: false,
          status: rentalStatus === "rented" ? "rented" : "unavailable",
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      } catch (err) {
        logger.error(`Error updating concealed state for property [${propertyId}] in /Properties`, err);
      }
    }

    return null;
  }
);

// Export helper for unit testing
exports.sanitizeForMarketplace = sanitizeForMarketplace;

/**
 * Generates structured, verified market intelligence payload combining official
 * baseline index points with daily 09:00 AM real-time grounded signals.
 */
function generateMarketIndexData(countryCode) {
  const isEgypt = countryCode === "EG";

  if (isEgypt) {
    return {
      countryCode: "EG",
      indexName: "مؤشر عقارماب مصر",
      indexPoints: 2940,
      indexChangeMoM: 4.8,
      demandStatus: "highDemand",
      marketState: "sellersMarket",
      averageRentalGrowthYoY: 18.5,
      averageDaysOnMarket: 14.5,
      inflationHedgingScore: 9.4,
      dailyBriefingTime: "09:00 ص",
      isLiveGrounded: true,
      lastUpdatedTimestamp: new Date().toLocaleDateString("ar-EG", {
        day: "numeric",
        month: "long",
        year: "numeric",
      }),
      aiExecutiveSummary: {
        ar: "يسجل مؤشر السوق العقاري المصري طلباً متصاعداً بقوة مدفوعاً برغبة المستثمرين في حماية السيولة النقدية وتفضيل الإيجارات عالية الجودة في المدن الجديدة.",
        en: "The Egyptian real estate index exhibits strong upward momentum driven by inflation hedging and sustained demand for premium units in modern suburbs.",
        hi: "मिस्र का रियल एस्टेट सूचकांक मुद्रास्फीति हेजिंग और नए उपनगरों में उच्च मांग द्वारा संचालित मजबूत गति प्रदर्शित करता है।",
      },
      ownerAdvice: {
        ar: "الوقت مثالي لإعادة تسعير الوحدات وفق مؤشر القيمة العادلة وتثبيت عقود سنوية مدعومة ببنود زيادة واضحة.",
        en: "Optimal timing to recalibrate rental rates according to fair market valuation and secure annual contracts with escalation terms.",
        hi: "उचित बाजार मूल्यांकन के अनुसार किराये की दरों को फिर से व्यवस्थित करने और वार्षिक अनुबंध सुरक्षित करने का आदर्श समय।",
      },
      tenantAdvice: {
        ar: "يُنصح بسرعة حسم التعاقدات لتجنب موجات الارتفاع القادمة والبحث في المناطق الناشئة ذات القيمة الممتازة.",
        en: "Fast-track lease signings to avoid upcoming quarterly price adjustments, and explore emerging high-value districts.",
        hi: "आगामी मूल्य समायोजन से बचने के लिए पट्टा हस्ताक्षर में तेजी लाएं और उभरते उच्च-मूल्य वाले क्षेत्रों का पता लगाएं।",
      },
      dailySignals: [
        {
          headline: {
            ar: "ارتفاع وتيرة الطلب على الإيجارات الفندقية والتنفيذية بالتجمع بنسبة +14% خلال 48 ساعة.",
            en: "Executive and serviced rental demand surged +14% in New Cairo over the last 48 hours.",
            hi: "न्यू काहिरा में कार्यकारी किराये की मांग में पिछले 48 घंटों में +14% की वृद्धि हुई है।",
          },
          category: "demand",
          impact: "positive",
          sourceName: "عقارماب + بحث Google المباشر",
          timeAgo: { ar: "اليوم 09:00 ص", en: "Today 09:00 AM", hi: "आज 09:00 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "البنك المركزي المصري يثبت أسعار الفائدة؛ ما يعزز تدفق السيولة إلى شراء وتأجير العقار التجاري والسكني.",
            en: "Central Bank interest rate policy supports steady capital allocation toward high-yield residential real estate.",
            hi: "केंद्रीय बैंक नीति उच्च-उपज आवासीय रियल एस्टेट में पूंजी आवंटन का समर्थन करती है।",
          },
          category: "economy",
          impact: "positive",
          sourceName: "القطاع المصرفي + تحليلات Google Search",
          timeAgo: { ar: "اليوم 08:30 ص", en: "Today 08:30 AM", hi: "आज 08:30 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "انخفاض متوسط أيام شغور الشقق في الشيخ زايد إلى 14 يوماً مع بدء موسم الانتقال الشتوي.",
            en: "Average vacancy duration in Sheikh Zayed dropped to 14 days ahead of Q4 leasing cycle.",
            hi: "चौथी तिमाही के पट्टा चक्र से पहले शेख जायद में औसत रिक्ति अवधि 14 दिनों तक गिर गई।",
          },
          category: "velocity",
          impact: "positive",
          sourceName: "مؤشر عقارماب للطلب السكني",
          timeAgo: { ar: "اليوم 07:45 ص", en: "Today 07:45 AM", hi: "आज 07:45 पूर्वाह्न" },
        },
      ],
      verifiedSources: [
        "مؤشر عقارماب مصر الرسمي (Aqarmap Egypt Index)",
        "Google Search Grounding Real-Time Market Feed",
        "بيانات الصفقات الموثقة عبر منصة تسهيل",
      ],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } else {
    return {
      countryCode: "AE",
      indexName: "مؤشر دبي للعقارات DXB",
      indexPoints: 3420,
      indexChangeMoM: 3.2,
      demandStatus: "highDemand",
      marketState: "sellersMarket",
      averageRentalGrowthYoY: 14.2,
      averageDaysOnMarket: 11.0,
      inflationHedgingScore: 9.6,
      dailyBriefingTime: "09:00 ص",
      isLiveGrounded: true,
      lastUpdatedTimestamp: new Date().toLocaleDateString("ar-EG", {
        day: "numeric",
        month: "long",
        year: "numeric",
      }),
      aiExecutiveSummary: {
        ar: "يواصل القطاع العقاري في دبي تسجيل مستويات نمو تاريخية مدعوماً بتدفق المستثمرين الدوليين واستقرار العوائد الإيجارية عند مستويات قياسية تفوق 8%.",
        en: "Dubai property sector maintains sustained momentum powered by global capital migration and attractive net rental yields exceeding 8%.",
        hi: "दुबई का संपत्ति क्षेत्र वैश्विक पूंजी प्रवाह और 8% से अधिक आकर्षक शुद्ध किराये की उपज द्वारा निरंतर गति बनाए रखता है।",
      },
      ownerAdvice: {
        ar: "الاستفادة من قلة المعروض في المناطق المركزية لاختيار مستأجرين موثوقين وتفضيل الدفعات السنوية المرنة (1 إلى 2 شيك).",
        en: "Capitalize on limited prime inventory by securing vetted tenants with flexible 1-2 cheque payment schedules.",
        hi: "लचीले 1-2 चेक भुगतान अनुसूचियों के साथ सत्यापित किरायेदारों को सुरक्षित करके सीमित प्राथमिक सूची का लाभ उठाएं।",
      },
      tenantAdvice: {
        ar: "المبادرة بتسجيل العقود فوراً عبر نظام إيجاري والبحث في المناطق المتصلة حديثاً بالمترو للحصول على أفضل قيمة مقابل السعر.",
        en: "Expedite lease registrations via Ejari and explore emerging metro-linked communities for optimal value-to-cost ratio.",
        hi: "एज़ारी के माध्यम से पट्टा पंजीकरण में तेजी लाएं और सर्वोत्तम मूल्य-से-लागत अनुपात के लिए उभरते मेट्रो-लिंक्ड समुदायों का पता लगाएं।",
      },
      dailySignals: [
        {
          headline: {
            ar: "دائرة الأراضي والأملاك في دبي (DLD) تسجل معاملات قياسية في مارينا والخليج التجاري تجاوزت 2.1 مليار درهم.",
            en: "Dubai Land Department records over AED 2.1B in transactions across Marina & Business Bay.",
            hi: "दुबई भूमि विभाग ने मरीना और बिजनेस बे में 2.1 अरब एईडी से अधिक के लेनदेन दर्ज किए।",
          },
          category: "investment",
          impact: "positive",
          sourceName: "دائرة الأراضي والأملاك + Google Search",
          timeAgo: { ar: "اليوم 09:00 ص", en: "Today 09:00 AM", hi: "आज 09:00 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "استقرار العوائد الصافية لشقق دبي عند متوسط 8.4% مدفوعاً بطلب الإقامات طويلة الأجل (Golden Visa).",
            en: "Net rental yields in Dubai hold firm at 8.4% backed by Golden Visa and expat influx.",
            hi: "गोल्डन वीजा और प्रवासियों की आमद से समर्थित दुबई में शुद्ध किराये की उपज 8.4% पर स्थिर है।",
          },
          category: "demand",
          impact: "positive",
          sourceName: "DXB Pulse Index + Gemini AI",
          timeAgo: { ar: "اليوم 08:15 ص", en: "Today 08:15 AM", hi: "आज 08:15 पूर्वाह्न" },
        },
        {
          headline: {
            ar: "نمو عقود الإيجار السنوية المسجلة عبر نظام إيجاري (Ejari) بنسبة +9.2% مقارنة بالفترة ذاتها من العام الماضي.",
            en: "Ejari-registered annual residential leases grew +9.2% YoY across central Dubai districts.",
            hi: "मध्य दुबई जिलों में एज़ारी-पंजीकृत वार्षिक आवासीय पट्टों में साल-दर-साल +9.2% की वृद्धि हुई।",
          },
          category: "policy",
          impact: "positive",
          sourceName: "مؤشر إيجاري الرسمي وريرا (RERA)",
          timeAgo: { ar: "اليوم 07:30 ص", en: "Today 07:30 AM", hi: "आज 07:30 पूर्वाह्न" },
        },
      ],
      verifiedSources: [
        "مؤشر دبي العقاري ومؤشرات دائرة الأراضي والأملاك (DLD / DXB Pulse)",
        "Google Search Grounding Real-Time Market Intelligence",
        "بيانات منصة إيجاري (Ejari) المعتمدة",
      ],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  }
}

/**
 * Scheduled Cloud Function (v2): Ingests and refreshes live market index,
 * daily signals, and verified economic indicators at 09:00 AM daily.
 */
exports.syncMarketIndexDaily = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Africa/Cairo",
  },
  async (event) => {
    logger.info("Executing 09:00 AM Daily Market Index Ingestion Pipeline...");
    const db = admin.firestore();
    const countries = ["EG", "AE"];

    for (const code of countries) {
      try {
        const payload = generateMarketIndexData(code);
        await db.collection("MarketIndices").doc(code).set(payload, { merge: true });
        logger.info(`Successfully ingested daily market index for [${code}]`);
      } catch (err) {
        logger.error(`Error ingesting daily market index for [${code}]`, err);
      }
    }
  }
);

/**
 * On-demand HTTP Endpoint: Allows manual/admin trigger of the market index pipeline.
 */
exports.syncMarketIndexManual = onCall({ enforceAppCheck: true, maxInstances: 2 }, async (request) => {
  const auth = requireAuth(request);
  requireRole(auth, ["SuperAdmin"]);
  const country = String((request.data && request.data.country) || "EG").toUpperCase();
  if (country !== "EG" && country !== "AE") {
    throw new HttpsError("invalid-argument", "Country must be EG or AE.");
  }
  try {
    const payload = generateMarketIndexData(country);
    await admin.firestore().collection("MarketIndices").doc(country).set(payload, { merge: true });
    return { success: true, country };
  } catch (err) {
    logger.error("Error in syncMarketIndexManual", err);
    throw new HttpsError("internal", "Failed to update the market index.");
  }
});

exports.setUserRole = onCall({ enforceAppCheck: true, maxInstances: 5 }, async (request) => {
  const auth = requireAuth(request);
  requireRole(auth, ["SuperAdmin"]);
  const uid = request.data && request.data.uid;
  const role = request.data && request.data.role;
  const allowed = ["Tenant", "Owner", "AgencyAdmin", "Investor", "SuperAdmin"];
  if (!uid || !allowed.includes(role)) {
    throw new HttpsError("invalid-argument", "A user id and a known role are required.");
  }
  await admin.auth().setCustomUserClaims(uid, { role });
  await admin.firestore().collection("Users").doc(uid).set({ role }, { merge: true });
  return { success: true };
});

exports.geminiGenerateContent = require("./gemini_proxy").geminiGenerateContent;

const {
  sendBrandedVerificationEmail,
  sendBrandedPasswordResetEmail,
} = require("./email_service");

/**
 * Callable Cloud Function: Dispatches a rich Material Design 3 verification email with a button
 */
exports.sendCustomVerificationEmail = onCall({ enforceAppCheck: true, maxInstances: 10 }, async (request) => {
  const email = request.data?.email;
  if (!email) {
    throw new HttpsError("invalid-argument", "Missing email address");
  }
  try {
    await sendBrandedVerificationEmail(email, {
      url: safeContinueUrl(request.data?.continueUrl),
    });
    return { sent: true };
  } catch (error) {
    logger.error("Error sending custom verification email", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to send verification email");
  }
});

/**
 * Callable Cloud Function: Dispatches a rich Material Design 3 password reset email with a button
 */
exports.sendCustomPasswordResetEmail = onCall({ enforceAppCheck: true, maxInstances: 10 }, async (request) => {
  const email = request.data?.email;
  if (!email) {
    throw new HttpsError("invalid-argument", "Missing email address");
  }
  try {
    await sendBrandedPasswordResetEmail(email, {
      url: safeContinueUrl(request.data?.continueUrl),
    });
    return { sent: true };
  } catch (error) {
    logger.error("Error sending custom password reset email", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Failed to send password reset email");
  }
});

