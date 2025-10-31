const mongoose = require('mongoose');

// Modèle Smartphone (doit correspondre à votre modèle existant)
const smartphoneSchema = new mongoose.Schema({
  marque: String,
  modele: String,
  prix: Number,
  stock: Number,
  couleur: String,
  image: String,
  ecran: {
    taille: Number,
    resolution: String,
    type: String
  },
  ram: Number,
  stockage: Number,
  camera: {
    principale: Number,
    frontale: Number
  },
  batterie: Number,
  os: String,
  processeur: String,
  enPromotion: Boolean,
  promotionPourcentage: Number
});

const Smartphone = mongoose.model('Smartphone', smartphoneSchema);
const smartphoneDB = [
  {
    marque: 'Samsung',
    modele: 'Galaxy S23 Ultra',
    prix: 1259,
    stock: 25,
    couleur: 'Noir',
    image: 'https://images.samsung.com/is/image/samsung/p6pim/fr/2302/gallery/fr-galaxy-s23-s918-sm-s918bzkgeub-534866917',
    ecran: { taille: 6.8, resolution: '1440x3088', type: 'Dynamic AMOLED 2X' },
    ram: 12,
    stockage: 512,
    camera: { principale: 200, frontale: 12 },
    batterie: 5000,
    os: 'Android',
    processeur: 'Snapdragon 8 Gen 2',
    enPromotion: true,
    promotionPourcentage: 10
  },
  {
    marque: 'Apple',
    modele: 'iPhone 15 Pro',
    prix: 1229,
    stock: 30,
    couleur: 'Titanium Naturel',
    image: 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/iphone-15-pro-finish-select-202309-6-7inch-naturaltitanium?wid=5120&hei=2880&fmt=p-jpg&qlt=80&.v=1692846359318',
    ecran: { taille: 6.1, resolution: '1179x2556', type: 'Super Retina XDR' },
    ram: 8,
    stockage: 256,
    camera: { principale: 48, frontale: 12 },
    batterie: 3274,
    os: 'iOS',
    processeur: 'A17 Pro',
    enPromotion: false
  },
  {
    marque: 'Google',
    modele: 'Pixel 8 Pro',
    prix: 999,
    stock: 15,
    couleur: 'Porcelain',
    image: 'https://storage.googleapis.com/gweb-uniblog-publish-prod/images/Pixel_8_Pro_Hero_1140x641.width-1200.format-webp.webp',
    ecran: { taille: 6.7, resolution: '1344x2992', type: 'LTPO OLED' },
    ram: 12,
    stockage: 256,
    camera: { principale: 50, frontale: 10.5 },
    batterie: 5050,
    os: 'Android',
    processeur: 'Google Tensor G3',
    enPromotion: true,
    promotionPourcentage: 15
  },
  {
    marque: 'OnePlus',
    modele: '11 5G',
    prix: 849,
    stock: 20,
    couleur: 'Vert Éternel',
    image: 'https://image01.oneplus.net/ebp/202301/05/1-m00-34-19-cpgm7gnvx7-akyjvaajvx5qk8nw179.png',
    ecran: { taille: 6.7, resolution: '1440x3216', type: 'LTPO3 Fluid AMOLED' },
    ram: 16,
    stockage: 256,
    camera: { principale: 50, frontale: 16 },
    batterie: 5000,
    os: 'Android',
    processeur: 'Snapdragon 8 Gen 2',
    enPromotion: true,
    promotionPourcentage: 5
  },
  {
    marque: 'Xiaomi',
    modele: '13T Pro',
    prix: 799,
    stock: 35,
    couleur: 'Bleu',
    image: 'https://i02.appmifile.com/164_operator_sg/05/09/2023/60b4d7d6e5b7a6d4e6c6d5e6f7g8h9i0j.png',
    ecran: { taille: 6.67, resolution: '1220x2712', type: 'CrystalRes AMOLED' },
    ram: 12,
    stockage: 512,
    camera: { principale: 50, frontale: 20 },
    batterie: 5000,
    os: 'Android',
    processeur: 'Dimensity 9200+',
    enPromotion: false
  },
  // ... ajoutez d'autres smartphones avec des images
];

// Connexion et insertion
async function seedDatabase() {
  try {
    // Connexion à MongoDB
    await mongoose.connect('mongodb://localhost:27017/smartphoneDB', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Connecté à MongoDB');

    // Vider la collection existante
    await Smartphone.deleteMany({});
    console.log('✅ Collection smartphones vidée');

    // Insérer les nouveaux smartphones
    await Smartphone.insertMany(smartphoneDB);
    console.log('✅ Données insérées avec succès');

    // Compter le nombre de documents
    const count = await Smartphone.countDocuments();
    console.log(`📱 ${count} smartphones insérés dans la base de données`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    process.exit(1);
  }
}

// Démarrer le seed
seedDatabase();