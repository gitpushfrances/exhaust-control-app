/**
 * ─────────────────────────────────────────────────────────────
 *  ADD BARANGAY SCRIPT — Exhaust Controller App
 *  Reusable script to add manually traced barangay polygons
 *  to Firestore /barangays collection.
 *
 *  HOW TO USE:
 *  1. Trace barangay in geojson.io
 *  2. Fill in the BARANGAY DATA section below
 *  3. Paste coordinates from geojson.io into POLYGON_COORDINATES
 *  4. Run: node add_barangay.js
 * ─────────────────────────────────────────────────────────────
 */

const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────
//  BARANGAY DATA — Edit this section for each barangay
// ─────────────────────────────────────────────────────────────

const BARANGAY = {
  id:               'guiuan-poblacion-ward-4',   // unique document ID — use kebab-case
  barangay_name:    'Poblacion Ward 4',           // exact barangay name
  municipality:     'Guiuan',                     // municipality name
  province:         'Eastern Samar',              // province name
  region:           'Region VIII',                // region name
};

// Paste coordinates from geojson.io here
// Format: [ [lng, lat], [lng, lat], ... ]
// NOTE: GeoJSON uses [longitude, latitude] order — NOT [lat, lng]
const POLYGON_COORDINATES = [
  [125.72618732534926, 11.03190528174187],
  [125.73034996029031, 11.02925977086852],
  [125.73352396943454, 11.031231138374665],
  [125.73370088141996, 11.031966567426394],
  [125.73359681554547, 11.032742851650326],
  [125.73281632149286, 11.033815346217906],
  [125.73199420109285, 11.033427205777713],
  [125.73083906989683, 11.034131986721988],
  [125.7294237740158,  11.034887836869729],
  [125.72743611583115, 11.033141207232347],
  [125.72689497328855, 11.03258963782099],
  [125.72618732534926, 11.03190528174187],  // closing point = first point
];

// ─────────────────────────────────────────────────────────────
//  DO NOT EDIT BELOW THIS LINE
// ─────────────────────────────────────────────────────────────

function calculateCentroid(coords) {
  let latSum = 0;
  let lngSum = 0;
  const n = coords.length - 1; // exclude closing point
  for (let i = 0; i < n; i++) {
    lngSum += coords[i][0];
    latSum += coords[i][1];
  }
  return {
    lat: latSum / n,
    lng: lngSum / n,
  };
}

function convertToFirestorePolygon(coords) {
  // Convert [lng, lat] GeoJSON format → {lat, lng} Firestore format
  return coords.map(([lng, lat]) => ({ lat, lng }));
}

async function addBarangay() {
  console.log('─────────────────────────────────────────────');
  console.log('Adding barangay:', BARANGAY.barangay_name);
  console.log('Municipality:  ', BARANGAY.municipality);
  console.log('Document ID:   ', BARANGAY.id);
  console.log('─────────────────────────────────────────────');

  // Check if document already exists
  const existing = await db.collection('barangays').doc(BARANGAY.id).get();
  if (existing.exists) {
    console.log('⚠️  Document already exists — OVERWRITING...');
  }

  const centroid = calculateCentroid(POLYGON_COORDINATES);
  const firestorePolygon = convertToFirestorePolygon(POLYGON_COORDINATES);

  const doc = {
    barangay_id:       BARANGAY.id,
    barangay_name:     BARANGAY.barangay_name,
    municipality_name: BARANGAY.municipality,
    province:          BARANGAY.province,
    region:            BARANGAY.region,
    center_lat:        centroid.lat,
    center_lng:        centroid.lng,
    boundary_polygon:  firestorePolygon,
    boundary_radius_m: 2000,   // fallback circle radius
    official_uid:      null,   // assigned when official is created
    is_active:         true,
    created_at:        admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection('barangays').doc(BARANGAY.id).set(doc);

  console.log('✅ Uploaded successfully!');
  console.log('   Centroid:', centroid.lat.toFixed(6), centroid.lng.toFixed(6));
  console.log('   Polygon points:', firestorePolygon.length);
  console.log('─────────────────────────────────────────────');
  console.log('Next barangay: edit BARANGAY and POLYGON_COORDINATES, run again.');
  console.log('─────────────────────────────────────────────');

  process.exit(0);
}

addBarangay().catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});