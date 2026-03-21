import { PrismaClient, Role, Badge } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()
const DEMO_PASSWORD = 'Super1234!'

// High-quality portrait URLs from randomuser.me (stable, no API key needed)
// These URLs are deterministic and always return the same face
const PORTRAITS = {
  women: [
    'https://randomuser.me/api/portraits/women/44.jpg',
    'https://randomuser.me/api/portraits/women/68.jpg',
    'https://randomuser.me/api/portraits/women/65.jpg',
    'https://randomuser.me/api/portraits/women/89.jpg',
    'https://randomuser.me/api/portraits/women/50.jpg',
    'https://randomuser.me/api/portraits/women/33.jpg',
    'https://randomuser.me/api/portraits/women/72.jpg',
    'https://randomuser.me/api/portraits/women/17.jpg',
  ],
  men: [
    'https://randomuser.me/api/portraits/men/32.jpg',
    'https://randomuser.me/api/portraits/men/75.jpg',
    'https://randomuser.me/api/portraits/men/44.jpg',
  ],
  parents: [
    'https://randomuser.me/api/portraits/women/22.jpg',
    'https://randomuser.me/api/portraits/men/86.jpg',
    'https://randomuser.me/api/portraits/women/55.jpg',
  ],
}

const nannyData = [
  {
    email: 'nanny1@supernanny.app', fullName: 'שירה מזרחי', phone: '052-4444441',
    avatarUrl: PORTRAITS.women[0],
    city: 'תל אביב', lat: 32.0853, lng: 34.7818,
    headline: 'מטפלת מנוסה עם 5 שנות ניסיון',
    bio: 'שלום! שמי שירה, בת 26 מתל אביב. יש לי ניסיון עשיר בטיפול בילדים בכל הגילאים, כולל תינוקות. אני סבלנית, אחראית ואוהבת ילדים מאוד.',
    rate: 65, years: 5, langs: ['Hebrew', 'English'],
    skills: ['Infant Care', 'Cooking', 'Homework Help', 'Arts & Crafts'],
    badges: [Badge.VERIFIED, Badge.EXPERIENCE_5_PLUS, Badge.TOP_RATED],
    rating: 4.9, reviews: 47,
  },
  {
    email: 'nanny2@supernanny.app', fullName: 'נועה גולדברג', phone: '052-4444442',
    avatarUrl: PORTRAITS.women[1],
    city: 'רמת גן', lat: 32.0833, lng: 34.8103,
    headline: 'בוגרת חינוך לגיל הרך',
    bio: 'אני נועה, בת 24, בוגרת תואר ראשון בחינוך לגיל הרך. מתמחה בטיפול בילדים גיל 0-6. מאמינה בגישה חיובית ומשחקית.',
    rate: 55, years: 3, langs: ['Hebrew', 'English', 'French'],
    skills: ['Early Childhood Education', 'Infant Care', 'Music', 'Swimming Supervision'],
    badges: [Badge.VERIFIED, Badge.FIRST_AID],
    rating: 4.7, reviews: 28,
  },
  {
    email: 'nanny3@supernanny.app', fullName: 'אור בן דוד', phone: '052-4444443',
    avatarUrl: PORTRAITS.men[0],
    city: 'פתח תקווה', lat: 32.0897, lng: 34.8872,
    headline: 'מטפל עם ניסיון בילדים מיוחדים',
    bio: 'שלום, אני אור בן 28. מתמחה בטיפול בילדים עם צרכים מיוחדים. בעל הכשרה בהנחיית ילדים עם אוטיזם ו-ADHD.',
    rate: 75, years: 6, langs: ['Hebrew', 'English', 'Arabic'],
    skills: ['Special Needs Care', 'Behavioral Therapy', 'Homework Help', 'Sign Language'],
    badges: [Badge.VERIFIED, Badge.BACKGROUND_CHECKED, Badge.EXPERIENCE_5_PLUS],
    rating: 4.8, reviews: 33,
  },
  {
    email: 'nanny4@supernanny.app', fullName: 'תמר אלוני', phone: '052-4444444',
    avatarUrl: PORTRAITS.women[2],
    city: 'תל אביב', lat: 32.0662, lng: 34.7750,
    headline: 'מטפלת מוסמכת עם אישור עבודה עם ילדים',
    bio: 'שמי תמר, בת 30. יש לי 8 שנות ניסיון בטיפול בילדים. אני מוסמכת בעזרה ראשונה ויש לי אישור עבודה עם ילדים.',
    rate: 70, years: 8, langs: ['Hebrew', 'Russian', 'English'],
    skills: ['Infant Care', 'First Aid', 'Cooking Nutritious Meals', 'Bedtime Routines'],
    badges: [Badge.VERIFIED, Badge.FIRST_AID, Badge.BACKGROUND_CHECKED, Badge.TOP_RATED, Badge.EXPERIENCE_5_PLUS],
    rating: 5.0, reviews: 62,
  },
  {
    email: 'nanny5@supernanny.app', fullName: 'יעל כהן', phone: '052-4444445',
    avatarUrl: PORTRAITS.women[3],
    city: 'הרצליה', lat: 32.1656, lng: 34.8441,
    headline: 'נאני פרטית עם ניסיון בבתי ערש',
    bio: 'אני יעל, בת 27. עבדתי 4 שנים כנאני פרטית אצל משפחות בהרצליה ורמת השרון. מיומנת בניהול לוחות זמנים.',
    rate: 60, years: 4, langs: ['Hebrew', 'English'],
    skills: ['Scheduling', 'Homework Help', 'Cooking', 'Driving'],
    badges: [Badge.VERIFIED, Badge.FAST_RESPONDER],
    rating: 4.6, reviews: 19,
  },
  {
    email: 'nanny6@supernanny.app', fullName: 'ליאת שרון', phone: '052-4444446',
    avatarUrl: PORTRAITS.women[4],
    city: 'חיפה', lat: 32.7940, lng: 34.9896,
    headline: 'מטפלת ותיקה מחיפה',
    bio: 'ליאת, בת 35, אמא לשני ילדים בעצמי ועם ניסיון של 10 שנים בטיפול בילדים. אני מבינה את הצרכים של ההורים.',
    rate: 58, years: 10, langs: ['Hebrew', 'English', 'Russian'],
    skills: ['All Ages Care', 'Infant Care', 'Meal Preparation', 'Educational Play'],
    badges: [Badge.VERIFIED, Badge.EXPERIENCE_5_PLUS, Badge.TOP_RATED],
    rating: 4.8, reviews: 41,
  },
  {
    email: 'nanny7@supernanny.app', fullName: 'ענת פרץ', phone: '052-4444447',
    avatarUrl: PORTRAITS.women[5],
    city: 'ראשון לציון', lat: 31.9730, lng: 34.7896,
    headline: 'סטודנטית לחינוך מיוחד',
    bio: 'שמי ענת, בת 22, סטודנטית שנה ג\' לחינוך מיוחד. מחפשת עבודה גמישה בשעות אחה"צ ובסופי שבוע.',
    rate: 45, years: 2, langs: ['Hebrew'],
    skills: ['Homework Help', 'Arts & Crafts', 'Outdoor Play', 'Reading'],
    badges: [Badge.VERIFIED],
    rating: 4.5, reviews: 11,
  },
  {
    email: 'nanny8@supernanny.app', fullName: 'מורן אלחדד', phone: '052-4444448',
    avatarUrl: PORTRAITS.women[6],
    city: 'נתניה', lat: 32.3215, lng: 34.8532,
    headline: 'מטפלת מקצועית עם ניסיון בחו"ל',
    bio: 'מורן, בת 29. עבדתי 3 שנים כנאני בלונדון ועוד 4 שנים בישראל. דוברת אנגלית ברמת שפת אם.',
    rate: 72, years: 7, langs: ['Hebrew', 'English'],
    skills: ['Bilingual Care', 'Infant Care', 'School Pickup', 'Cooking'],
    badges: [Badge.VERIFIED, Badge.EXPERIENCE_5_PLUS, Badge.BACKGROUND_CHECKED],
    rating: 4.9, reviews: 38,
  },
  {
    email: 'nanny9@supernanny.app', fullName: 'רוני אביב', phone: '052-4444449',
    avatarUrl: PORTRAITS.men[1],
    city: 'גבעתיים', lat: 32.0693, lng: 34.8127,
    headline: 'מטפל גברי - נאמן ואחראי',
    bio: 'שלום, אני רוני בן 26. יש לי אחיינים קטנים ואני אוהב לעבוד עם ילדים. עוסק בחינוך גופני.',
    rate: 55, years: 3, langs: ['Hebrew', 'English'],
    skills: ['Sports & Physical Activity', 'Homework Help', 'Outdoor Activities'],
    badges: [Badge.VERIFIED],
    rating: 4.7, reviews: 15,
  },
  {
    email: 'nanny10@supernanny.app', fullName: 'שושנה ביטון', phone: '052-4444450',
    avatarUrl: PORTRAITS.women[7],
    city: 'אשדוד', lat: 31.8044, lng: 34.6553,
    headline: 'מטפלת ותיקה מאשדוד',
    bio: 'שושנה, בת 42. אמא ל-3 ילדים ועם ניסיון של 15 שנה. מכירה את כל מה שנדרש לטיפול ילדים מקצועי.',
    rate: 50, years: 15, langs: ['Hebrew', 'French', 'Arabic'],
    skills: ['All Ages', 'Cooking', 'Infant Care', 'Homework Help'],
    badges: [Badge.VERIFIED, Badge.EXPERIENCE_5_PLUS],
    rating: 4.6, reviews: 29,
  },
]

async function main() {
  console.log('🌱 Starting database seed...')
  const hash = await bcrypt.hash(DEMO_PASSWORD, 12)

  // Admin
  await prisma.user.upsert({
    where: { email: 'admin@supernanny.app' },
    update: {},
    create: { email: 'admin@supernanny.app', passwordHash: hash, fullName: 'Super Admin', role: Role.ADMIN, isVerified: true },
  })

  // Parents (with avatars)
  const parentEmails = [
    { email: 'parent1@supernanny.app', fullName: 'דנה כהן', phone: '052-1111111', avatarUrl: PORTRAITS.parents[0] },
    { email: 'parent2@supernanny.app', fullName: 'יונתן לוי', phone: '053-2222222', avatarUrl: PORTRAITS.parents[1] },
    { email: 'parent3@supernanny.app', fullName: 'מיכל אברהם', phone: '054-3333333', avatarUrl: PORTRAITS.parents[2] },
  ]

  for (const p of parentEmails) {
    await prisma.user.upsert({
      where: { email: p.email },
      update: { avatarUrl: p.avatarUrl },
      create: { ...p, passwordHash: hash, role: Role.PARENT, isVerified: true },
    })
  }

  // Nannies
  for (const data of nannyData) {
    const user = await prisma.user.upsert({
      where: { email: data.email },
      update: { avatarUrl: data.avatarUrl },
      create: {
        email: data.email, passwordHash: hash, fullName: data.fullName,
        phone: data.phone, role: Role.NANNY, isVerified: true,
        avatarUrl: data.avatarUrl,
      },
    })

    const profile = await prisma.nannyProfile.upsert({
      where: { userId: user.id },
      update: {},
      create: {
        userId: user.id,
        headline: data.headline,
        bio: data.bio,
        hourlyRateNis: data.rate,
        yearsExperience: data.years,
        languages: data.langs,
        skills: data.skills,
        badges: data.badges,
        isVerified: true,
        isAvailable: true,
        latitude: data.lat,
        longitude: data.lng,
        city: data.city,
        rating: data.rating,
        reviewsCount: data.reviews,
        completedJobs: data.reviews,
      },
    })

    // Availability (Sun–Sat)
    for (let day = 0; day <= 6; day++) {
      const from = day === 6 ? '10:00' : '08:00'
      const to = day === 5 ? '23:00' : day === 6 ? '20:00' : '22:00'
      await prisma.availability.upsert({
        where: { nannyProfileId_dayOfWeek: { nannyProfileId: profile.id, dayOfWeek: day } },
        update: {},
        create: { nannyProfileId: profile.id, dayOfWeek: day, fromTime: from, toTime: to },
      })
    }
  }

  console.log(`✅ Seed complete — ${nannyData.length} nannies, ${parentEmails.length} parents, 1 admin`)
  console.log('   All users seeded with realistic profile images')
  console.log('\n🔑 Demo credentials (password: Super1234!):')
  console.log('   parent1@supernanny.app  → Parent')
  console.log('   nanny1@supernanny.app   → Nanny')
  console.log('   admin@supernanny.app    → Admin')
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
