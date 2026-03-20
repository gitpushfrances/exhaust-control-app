/**
 * ─────────────────────────────────────────────────────────────
 *  ADD BARANGAY SCRIPT — Exhaust Controller App
 * ─────────────────────────────────────────────────────────────
 */

const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const BARANGAYS = {

  lupok: {
    meta: {
      id:            'guiuan-lupok',
      barangay_name: 'Lupok',
      municipality:  'Guiuan',
      province:      'Eastern Samar',
      region:        'Region VIII',
    },
    coordinates: [
      [125.71422871035998, 11.044113885646354],
      [125.7136450450136,  11.044518618099545],
      [125.7132136472307,  11.04414502282819],
      [125.7132136472307,  11.043572175822675],
      [125.71303601284876, 11.043273298679765],
      [125.71283300212804, 11.043273298679765],
      [125.71265536774604, 11.043049140623864],
      [125.71270612042622, 11.042775169432957],
      [125.71245235702844, 11.042445158342318],
      [125.71251579787804, 11.041971934243065],
      [125.71237622800692, 11.041822494894461],
      [125.71176719584332, 11.041685508759954],
      [125.71174181950323, 11.040751510677282],
      [125.71207171192577, 11.040664337370913],
      [125.71290913115149, 11.039169933815913],
      [125.71114547550911, 11.038136300241916],
      [125.71118354001857, 11.037837417566251],
      [125.71321364723394, 11.038783878328886],
      [125.71350547514555, 11.037600801899444],
      [125.71317558272307, 11.037401546453737],
      [125.71318827089249, 11.037252104779455],
      [125.71339128161452, 11.036990581668135],
      [125.7129852601717,  11.036616976819161],
      [125.71295988383167, 11.036355453142406],
      [125.71412719547988, 11.037065302580643],
      [125.71476160398356, 11.037003035155536],
      [125.71506612006596, 11.03675396531915],
      [125.71374655037715, 11.036044115128561],
      [125.7138988084177,  11.03557088071399],
      [125.71440633522224, 11.035707869701767],
      [125.71462203411363, 11.036106382756941],
      [125.71551020601953, 11.036455081236937],
      [125.71580203393125, 11.036293185565555],
      [125.71629687256501, 11.036081475706908],
      [125.716753646688,   11.036106382756941],
      [125.71715966813088, 11.036517348779526],
      [125.717299238002,   11.036704151326774],
      [125.71754031323354, 11.036816232798358],
      [125.7177306357849,  11.036816232798358],
      [125.71811128088763, 11.037563441513],
      [125.71833967746943, 11.037862320244926],
      [125.71917709669515, 11.03837291125491],
      [125.71851731185012, 11.041585878215955],
      [125.7184411828299,  11.041884757076616],
      [125.71821279576773, 11.042320621535154],
      [125.71787021517582, 11.043130082386384],
      [125.717641828115,   11.043366693598003],
      [125.71723580667214, 11.043665570645786],
      [125.7169693550992,  11.04372783665822],
      [125.71554828005003, 11.043989353770783],
      [125.71422871035998, 11.044113885646354],
    ],
  },

  salug: {
    meta: {
      id:            'guiuan-salug',
      barangay_name: 'Salug',
      municipality:  'Guiuan',
      province:      'Eastern Samar',
      region:        'Region VIII',
    },
    coordinates: [
      [125.73060866003686, 11.029220130776807],
      [125.7318676874981,  11.028154329101909],
      [125.73100856623472, 11.027675052077427],
      [125.7304103130611,  11.027039299511415],
      [125.7308323242387,  11.026810687641188],
      [125.73119636472958, 11.026126872214832],
      [125.73241719654948, 11.024133333282663],
      [125.73537973017773, 11.022202523750238],
      [125.73705499071684, 11.021010285936867],
      [125.7376969273558,  11.020729398428424],
      [125.73820500668776, 11.021269690024955],
      [125.7387861291026,  11.022251730293554],
      [125.73864755447391, 11.024246086218852],
      [125.73937670589618, 11.026518411978415],
      [125.73855641054541, 11.028218171735091],
      [125.73531168671343, 11.030383114668112],
      [125.73478305193271, 11.030311546561748],
      [125.7341997307945,  11.030490466795925],
      [125.73399921415296, 11.030884090926648],
      [125.73379869751142, 11.031080902794741],
      [125.73354349451427, 11.03117036269083],
      [125.73243153859352, 11.030401006692003],
      [125.73060866003686, 11.029220130776807],
    ],
  },

};

function calculateCentroid(coords) {
  let latSum = 0;
  let lngSum = 0;
  const n = coords.length - 1;
  for (let i = 0; i < n; i++) {
    lngSum += coords[i][0];
    latSum += coords[i][1];
  }
  return { lat: latSum / n, lng: lngSum / n };
}

function convertToFirestorePolygon(coords) {
  return coords.map(([lng, lat]) => ({ lat, lng }));
}

async function addBarangay(key) {
  const selected = BARANGAYS[key];
  const { meta, coordinates } = selected;

  console.log('─────────────────────────────────────────────');
  console.log('Adding barangay:', meta.barangay_name);
  console.log('Municipality:  ', meta.municipality);
  console.log('Document ID:   ', meta.id);
  console.log('─────────────────────────────────────────────');

  const existing = await db.collection('barangays').doc(meta.id).get();
  if (existing.exists) {
    console.log('⚠️  Document already exists — OVERWRITING...');
  }

  const centroid = calculateCentroid(coordinates);
  const firestorePolygon = convertToFirestorePolygon(coordinates);

  const doc = {
    barangay_id:       meta.id,
    barangay_name:     meta.barangay_name,
    municipality_name: meta.municipality,
    province:          meta.province,
    region:            meta.region,
    center_lat:        centroid.lat,
    center_lng:        centroid.lng,
    boundary_polygon:  firestorePolygon,
    boundary_radius_m: 2000,
    official_uid:      null,
    is_active:         true,
    created_at:        admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('barangays').doc(meta.id).set(doc);

  console.log('✅ Uploaded successfully!');
  console.log('   Centroid:', centroid.lat.toFixed(6), centroid.lng.toFixed(6));
  console.log('   Polygon points:', firestorePolygon.length);
  console.log('─────────────────────────────────────────────');
}

async function addAll() {
  for (const key of Object.keys(BARANGAYS)) {
    await addBarangay(key);
  }
  console.log('All barangays uploaded. Done.');
  process.exit(0);
}

addAll().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});