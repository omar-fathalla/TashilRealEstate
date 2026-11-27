"use strict";

// TAQ-201: one list for both the server filter (agency_text_filter.test.js) and the rules
// (rules.test.js), so the two stay in step.
const REFUSED = [
  "Delta 0 five 0 one 2 three 4",
  "Delta zero+five+zero+one+two+three+four",
  "Delta zero/five/zero/one/two/three/four",
  "دلتا صفر خمسة صفر واحد أثنين ثلاثة أربعة",
  "دلتا ثمانى ثمانى ثمانى ثمانى ثمانى ثمانى ثمانى",
  "Delta x\u3002com",
  "Delta x\uff0ecom",
  "Delta x.shop",
  "Delta x.store",
  "Delta x .com",
  "Delta x.Me",
  "Delta x.Co",
  "Delta x.In",
  "Delta x.Us",
  "عقار.com",
];

const ALLOWED = [
  "Seven Seas Realty",
  "One Two Three Homes",
  "Since 2005. Info and viewings on request. Five stars from 300 owners.",
  "We manage units in Dubai Marina. Commercial and residential.",
  "Al-Futtaim Real Estate, open 24/7, one team",
  "St. Regis Homes, Ph.D. advisers, Tashil Aqar L.L.C",
  "U.A.E. specialists, e.g. villas. Rated 4.5 by owners.",
  "Since 2005, 120 units. Top 10 agency in Dubai. Me and my team",
  "سبع بحار للعقارات",
  "الأولى للعقارات، ثلاثة أبراج",
];

module.exports = { REFUSED, ALLOWED };
