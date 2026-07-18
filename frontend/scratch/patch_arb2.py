import json
import os

translations = {
    "uz": {
        "tutorial_tourTitle": "Plately Interaktiv Qo'llanmasi",
        "tutorial_tourDesc": "Xush kelibsiz! Keling, Plately bo'ylab 1 daqiqalik qisqacha sayohat qilamiz. Biz sizga ingredientlarni qanday boshqarishni, mos retseptlarni topishni va pishirishni qanday boshlashni ko'rsatamiz!",
        "tutorial_startTour": "Boshlash 🚀",
        "tutorial_skipTour": "O'tkazib yuborish",
        "tutorial_shelfIntroTitle": "Sizning Raqamli Javoningiz",
        "tutorial_shelfIntroDesc": "Bu sizning raqamli muzlatgich va omborxonangiz. Bu yerda siz miqdorlarni va yaroqlilik muddatlarini kuzatishingiz mumkin — ovqat buzilishidan oldin sizni ogohlantiramiz. Keling, bu qanday ishlashini ko'ramiz!",
        "tutorial_nextArrow": "Keyingi →",
        "tutorial_addIntroTitle": "Ingredientlarni Qo'shish",
        "tutorial_addIntroDesc": "Ingredientlarni qo'shish uchun pastki menyudagi Skanerlash (kamera belgisi) tugmasini bosing. Qani, bosing!",
        "tutorial_bypassScan": "O'tish (Skanerlashga borish)",
        "tutorial_scanIntroTitle": "Skanerlash va Qo'lda Qo'shish",
        "tutorial_scanIntroDesc": "Bu yerda siz cheklarni, shtrix-kodlarni skanerlashingiz yoki ingredientlar suratini olishingiz mumkin. Ushbu qo'llanma uchun biz tovuq qovurish retsepti uchun kerakli 5 ta qalbaki ingredientni avtomatik yuklaymiz.",
        "tutorial_loadMock": "Qalbaki Ingredientlarni Yuklash 🛒",
        "tutorial_shelfAddedTitle": "Ingredientlar Yuklandi!",
        "tutorial_shelfAddedDesc": "Ajoyib! Biz bularni yukladik: Tovuq Go'shti, Brokkoli, Soya Sousi, Sarimsoq va Kunjut Yog'i. Keling, nima pishirish mumkinligini ko'ramiz! Mos retseptlarni topish uchun Pishirish tugmasini (chapdagi restoran belgisi) bosing.",
        "tutorial_bypassCook": "O'tish (Pishirishga borish)",
        "tutorial_roamCookTitle": "5 Darajali Tavsiyalar",
        "tutorial_roamCookDesc": "Bu yerda siz 5 xil tavsiya sahifalarini ko'rasiz (Mukammal, Siz uchun, Ishlatib yuborish, Qisman, Kashf qilish). Ularni o'rganish uchun bosib ko'ring! Tayyor bo'lganingizda, Mukammal bo'limidagi \"Qovurilgan Tovuq\" retsepti kartasini bosing.",
        "tutorial_recipeDetailTitle": "Retsept Tafsilotlari",
        "tutorial_recipeDetailDesc": "Bu yerda siz ingredientlar ro'yxatini va qadamlarni ko'rasiz. Boshlash uchun sahifa pastidagi \"Pishirishni Boshlash\" tugmasini bosing!",
        "tutorial_cookingPrepTitle": "Tayyorgarlik va Ingredientlar",
        "tutorial_cookingPrepDesc": "Olovni yoqishdan oldin, ingredientlarni yuving va to'g'rang. Pishirish yordamchisini ishga tushirish uchun \"Qadam-ba-qadam Boshlash\" tugmasini bosing!",
        "tutorial_cookingRunTitle": "Pishirish Yordamchisi",
        "tutorial_cookingRunDesc": "Yordamchi sizni qadam-ba-qadam boshqaradi. Siz shuningdek, o'zgartirishlar yoki pishirish haqidagi savollar uchun pastdagi AI yordamchisi bilan gaplashishingiz mumkin! Retsept qadamlarini bajaring va oxirgi qadamda \"Tugatish\" ni bosing.",
        "tutorial_finishTitle": "Qo'llanma Yakunlandi!",
        "tutorial_finishDesc": "Tabriklaymiz! Siz Plately pishirish qo'llanmasini yakunladingiz.\n\nEslatma: Ushbu qo'llanmada ishlatilgan barcha ingredientlar va ma'lumotlar saqlanmaydi. Bu ilovaning kichik bir qismi xolos. O'z pishirish sayohatingizni boshlash uchun \"Qo'llanmani Tugatish\" ni bosing!",
        "tutorial_finishTour": "Qo'llanmani Tugatish 🏁"
    },
    "uz_Cyrl": {
        "tutorial_tourTitle": "Plately Интерактив Қўлланмаси",
        "tutorial_tourDesc": "Хуш келибсиз! Келинг, Plately бўйлаб 1 дақиқалик қисқача саёҳат қиламиз. Биз сизга ингредиентларни қандай бошқаришни, мос рецептларни топишни ва пиширишни қандай бошлашни кўрсатамиз!",
        "tutorial_startTour": "Бошлаш 🚀",
        "tutorial_skipTour": "Ўтказиб юбориш",
        "tutorial_shelfIntroTitle": "Сизнинг Рақамли Жавонингиз",
        "tutorial_shelfIntroDesc": "Бу сизнинг рақамли музлатгич ва омборхонангиз. Бу ерда сиз миқдорларни ва яроқлилик муддатларини кузатишингиз мумкин — овқат бузилишидан олдин сизни огоҳлантирамиз. Келинг, бу қандай ишлашини кўрамиз!",
        "tutorial_nextArrow": "Кейинги →",
        "tutorial_addIntroTitle": "Ингредиентларни Қўшиш",
        "tutorial_addIntroDesc": "Ингредиентларни қўшиш учун пастки менюдаги Сканерлаш (камера белгиси) тугмасини босинг. Қани, босинг!",
        "tutorial_bypassScan": "Ўтиш (Сканерлашга бориш)",
        "tutorial_scanIntroTitle": "Сканерлаш ва Қўлда Қўшиш",
        "tutorial_scanIntroDesc": "Бу ерда сиз чекларни, штрих-кодларни сканерлашингиз ёки ингредиентлар суратини олишингиз мумкин. Ушбу қўлланма учун биз товуқ қовуриш рецепти учун керакли 5 та қалбаки ингредиентни автоматик юклаймиз.",
        "tutorial_loadMock": "Қалбаки Ингредиентларни Юклаш 🛒",
        "tutorial_shelfAddedTitle": "Ингредиентлар Юкланди!",
        "tutorial_shelfAddedDesc": "Ажойиб! Биз буларни юкладик: Товуқ Гўшти, Брокколи, Соя Соуси, Саримсоқ ва Кунжут Ёғи. Келинг, нима пишириш мумкинлигини кўрамиз! Мос рецептларни топиш учун Пишириш тугмасини (чапдаги ресторан белгиси) босинг.",
        "tutorial_bypassCook": "Ўтиш (Пиширишга бориш)",
        "tutorial_roamCookTitle": "5 Даражали Тавсиялар",
        "tutorial_roamCookDesc": "Бу ерда сиз 5 хил тавсия саҳифаларини кўрасиз (Мукаммал, Сиз учун, Ишлатиб юбориш, Қисман, Кашф қилиш). Уларни ўрганиш учун босиб кўринг! Тайёр бўлганингизда, Мукаммал бўлимидаги \"Қовурилган Товуқ\" рецепти картасини босинг.",
        "tutorial_recipeDetailTitle": "Рецепт Тафсилотлари",
        "tutorial_recipeDetailDesc": "Бу ерда сиз ингредиентлар рўйхатини ва қадамларни кўрасиз. Бошлаш учун саҳифа пастидаги \"Пиширишни Бошлаш\" тугмасини босинг!",
        "tutorial_cookingPrepTitle": "Тайёргарлик ва Ингредиентлар",
        "tutorial_cookingPrepDesc": "Оловни ёқишдан олдин, ингредиентларни ювинг ва тўғранг. Пишириш ёрдамчисини ишга тушириш учун \"Қадам-ба-қадам Бошлаш\" тугмасини босинг!",
        "tutorial_cookingRunTitle": "Пишириш Ёрдамчиси",
        "tutorial_cookingRunDesc": "Ёрдамчи сизни қадам-ба-қадам бошқаради. Сиз шунингдек, ўзгартиришлар ёки пишириш ҳақидаги саволлар учун пастдаги AI ёрдамчиси билан гаплашишингиз мумкин! Рецепт қадамларини бажаринг ва охирги қадамда \"Тугатиш\" ни босинг.",
        "tutorial_finishTitle": "Қўлланма Якунланди!",
        "tutorial_finishDesc": "Табриклаймиз! Сиз Plately пишириш қўлланмасини якунладингиз.\n\nЭслатма: Ушбу қўлланмада ишлатилган барча ингредиентлар ва маълумотлар сақланмайди. Бу илованинг кичик бир қисми холос. Ўз пишириш саёҳатингизни бошлаш учун \"Қўлланмани Тугатиш\" ни босинг!",
        "tutorial_finishTour": "Қўлланмани Тугатиш 🏁"
    },
    "ru": {
        "tutorial_tourTitle": "Интерактивный тур Plately",
        "tutorial_tourDesc": "Добро пожаловать! Давайте совершим быструю 1-минутную экскурсию по Plately. Мы покажем вам, как управлять ингредиентами, находить подходящие рецепты и начать готовить!",
        "tutorial_startTour": "Начать тур 🚀",
        "tutorial_skipTour": "Пропустить",
        "tutorial_shelfIntroTitle": "Ваша цифровая полка",
        "tutorial_shelfIntroDesc": "Это ваш цифровой холодильник и кладовая. Здесь вы можете отслеживать количество и сроки годности — мы предупредим вас до того, как продукты испортятся. Посмотрим, как это работает!",
        "tutorial_nextArrow": "Далее →",
        "tutorial_addIntroTitle": "Добавить ингредиенты",
        "tutorial_addIntroDesc": "Чтобы добавить ингредиенты, нажмите на вкладку Сканировать (значок камеры) внизу. Давайте, нажмите!",
        "tutorial_bypassScan": "Пропустить (Перейти к сканированию)",
        "tutorial_scanIntroTitle": "Сканирование и добавление",
        "tutorial_scanIntroDesc": "Здесь вы можете сканировать чеки, штрихкоды или сделать фото ингредиентов. Для этого руководства мы автоматически загрузим 5 тестовых ингредиентов для рецепта жареной курицы.",
        "tutorial_loadMock": "Загрузить тестовые ингредиенты 🛒",
        "tutorial_shelfAddedTitle": "Ингредиенты загружены!",
        "tutorial_shelfAddedDesc": "Отлично! Мы загрузили: Куриная грудка, Брокколи, Соевый соус, Чеснок и Кунжутное масло. Давайте посмотрим, что мы можем приготовить! Нажмите на вкладку Готовить (значок ресторана), чтобы найти рецепты.",
        "tutorial_bypassCook": "Пропустить (Перейти к рецептам)",
        "tutorial_roamCookTitle": "5 уровней рекомендаций",
        "tutorial_roamCookDesc": "Здесь вы видите 5 вкладок с рекомендациями (Идеально, Для вас, Использовать, Почти, Изучить). Нажмите на них, чтобы изучить! Когда будете готовы, нажмите на карточку рецепта \"Жареная курица\" на вкладке Идеально.",
        "tutorial_recipeDetailTitle": "Детали рецепта",
        "tutorial_recipeDetailDesc": "Здесь вы видите список ингредиентов и шаги. Нажмите кнопку \"Начать готовить\" внизу страницы, чтобы начать!",
        "tutorial_cookingPrepTitle": "Подготовка и ингредиенты",
        "tutorial_cookingPrepDesc": "Перед тем как включить плиту, вымойте и нарежьте ингредиенты. Нажмите кнопку \"Пошаговое руководство\", чтобы запустить кулинарного помощника!",
        "tutorial_cookingRunTitle": "Кулинарный помощник",
        "tutorial_cookingRunDesc": "Помощник шаг за шагом проведет вас по рецепту. Вы также можете пообщаться с ИИ внизу экрана для замены ингредиентов или вопросов! Пройдите шаги рецепта и нажмите \"Завершить\" на последнем.",
        "tutorial_finishTitle": "Тур завершен!",
        "tutorial_finishDesc": "Поздравляем! Вы завершили кулинарный тур Plately.\n\nПримечание: Все ингредиенты и данные из этого тура не будут сохранены. Это лишь малая часть приложения. Нажмите \"Завершить тур\", чтобы начать свой собственный путь!",
        "tutorial_finishTour": "Завершить тур 🏁"
    },
    "ko": {
        "tutorial_tourTitle": "Plately 인터랙티브 투어",
        "tutorial_tourDesc": "환영합니다! Plately의 1분 인터랙티브 투어를 시작하겠습니다. 재료를 관리하고, 맞는 레시피를 찾고, 요리를 시작하는 방법을 보여드릴게요!",
        "tutorial_startTour": "투어 시작 🚀",
        "tutorial_skipTour": "건너뛰기",
        "tutorial_shelfIntroTitle": "디지털 선반",
        "tutorial_shelfIntroDesc": "이곳은 여러분의 디지털 냉장고이자 팬트리입니다. 수량과 유통기한을 추적할 수 있으며, 음식이 상하기 전에 알려드립니다. 어떻게 작동하는지 볼까요!",
        "tutorial_nextArrow": "다음 →",
        "tutorial_addIntroTitle": "재료 추가하기",
        "tutorial_addIntroDesc": "재료를 추가하려면 하단의 스캔 탭(카메라 아이콘)을 누르세요. 어서 눌러보세요!",
        "tutorial_bypassScan": "건너뛰기 (스캔으로 이동)",
        "tutorial_scanIntroTitle": "스캔 및 수동 추가",
        "tutorial_scanIntroDesc": "영수증, 바코드를 스캔하거나 재료 사진을 찍을 수 있습니다. 이 튜토리얼에서는 닭고기 볶음 레시피에 필요한 5가지 가상 재료를 자동으로 불러옵니다.",
        "tutorial_loadMock": "가상 재료 불러오기 🛒",
        "tutorial_shelfAddedTitle": "재료 불러오기 완료!",
        "tutorial_shelfAddedDesc": "좋습니다! 닭가슴살, 브로콜리, 간장, 마늘, 참기름을 불러왔습니다. 무엇을 요리할 수 있을지 볼까요! 요리 탭(레스토랑 아이콘)을 눌러 레시피를 찾아보세요.",
        "tutorial_bypassCook": "건너뛰기 (요리로 이동)",
        "tutorial_roamCookTitle": "5단계 추천",
        "tutorial_roamCookDesc": "5가지 추천 탭(완벽 일치, 추천, 활용, 아쉬움, 탐색)이 있습니다. 탭을 눌러 둘러보세요! 준비가 되면 완벽 일치 탭의 \"닭고기 볶음\" 레시피 카드를 누르세요.",
        "tutorial_recipeDetailTitle": "레시피 상세 정보",
        "tutorial_recipeDetailDesc": "여기서 재료 목록과 요리 단계를 볼 수 있습니다. 페이지 하단의 \"요리 시작\" 버튼을 눌러 시작하세요!",
        "tutorial_cookingPrepTitle": "준비 및 재료",
        "tutorial_cookingPrepDesc": "불을 켜기 전에 재료를 씻고 썰어주세요. \"단계별 시작\" 버튼을 눌러 요리 도우미를 실행하세요!",
        "tutorial_cookingRunTitle": "요리 도우미",
        "tutorial_cookingRunDesc": "도우미가 단계별로 안내합니다. 대체 재료나 질문이 있다면 하단의 AI 도우미와 채팅할 수도 있어요! 레시피 단계를 따라가고 마지막 단계에서 \"완료\"를 누르세요.",
        "tutorial_finishTitle": "튜토리얼 완료!",
        "tutorial_finishDesc": "축하합니다! Plately 요리 투어를 완료했습니다.\n\n참고: 이 튜토리얼에 사용된 모든 재료와 데이터는 저장되지 않습니다. 이것은 앱의 아주 작은 부분일 뿐입니다. \"투어 완료\"를 눌러 나만의 요리 여정을 시작하세요!",
        "tutorial_finishTour": "투어 완료 🏁"
    }
}

base_path = "d:/dev/projects/Plately/frontend/lib/l10n"

for lang_code, trans in translations.items():
    file_path = os.path.join(base_path, f"app_{lang_code}.arb")
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        # update keys
        for k, v in trans.items():
            data[k] = v
            
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"Updated {file_path}")
