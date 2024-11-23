const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createUsers() {
  try {
    // Create homeowner
    await db.collection('users').doc('user-id').set({
      uid: 'user-id',
      email: 'user@example.com',
      name: 'User Name',
      role: 'homeowner',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('Homeowner created successfully');

    // Create service provider
    await db.collection('users').doc('provider-id').set({
      uid: 'provider-id',
      email: 'provider@example.com',
      name: 'Provider Name',
      role: 'provider',
      serviceType: 'Plumbing',
      isVerified: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('Service Provider created successfully');

    // Create admin
    await db.collection('users').doc('admin-id').set({
      uid: 'admin-id',
      email: 'admin@example.com',
      name: 'Admin Name',
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('Admin created successfully');

  } catch (error) {
    console.error('Error creating users:', error);
  }
}

// Run the function
createUsers();
