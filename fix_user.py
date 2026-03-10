from passlib.context import CryptContext
import asyncio
import motor.motor_asyncio

pwd_context = CryptContext(schemes=['bcrypt'], deprecated='auto')
password_hash = pwd_context.hash('abc12345')

async def update():
    client = motor.motor_asyncio.AsyncIOMotorClient(
        'mongodb://admin:admin123@mongodb:27017/crop_disease_db?authSource=admin'
    )
    db = client.crop_disease_db
    # Delete old broken user and create fresh one
    await db.users.delete_many({'email': 'abc@gmail.com'})
    result = await db.users.insert_one({
        'name': 'Test User',
        'email': 'abc@gmail.com',
        'phone': '+919999000099',
        'hashed_password': password_hash,
        'is_active': True,
        'preferred_language': 'en'
    })
    print('User created with id:', result.inserted_id)

asyncio.run(update())
