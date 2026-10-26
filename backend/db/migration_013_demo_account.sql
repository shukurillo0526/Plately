-- Migration 013: Unified Demo Account Seed
-- Creates/updates demo@plately.app with password '12345678'
-- Configures merchant owner role for Kamolon (Plately.workshop) and consumer profile (Plately.app)

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_user_id uuid := '997c380f-c8c7-44e6-86e0-e85a0151af98';
  v_restaurant_id uuid := '7e1dd08c-c95d-496b-86d0-f7b40d7f9cdf';
  v_branch_id uuid := '5ba11ac4-2e44-4ee2-9faa-15ae7db68574';
  v_enc_pass text;
BEGIN
  -- Generate bcrypt hash for '12345678'
  v_enc_pass := crypt('12345678', gen_salt('bf'));

  -- 1. Ensure user exists in auth.users
  IF EXISTS (SELECT 1 FROM auth.users WHERE id = v_user_id OR email = 'demo@plately.app') THEN
    UPDATE auth.users
    SET
      encrypted_password = v_enc_pass,
      email_confirmed_at = COALESCE(email_confirmed_at, now()),
      raw_app_meta_data = jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email'),
        'role', 'owner',
        'staff_role', 'owner',
        'restaurant_id', v_restaurant_id,
        'restaurant_name', 'Kamolon',
        'restaurant_slug', 'kamolon-b87695',
        'branch_id', v_branch_id
      ),
      raw_user_meta_data = jsonb_build_object(
        'name', 'Demo Manager',
        'display_name', 'Demo Manager',
        'role', 'owner',
        'restaurant_id', v_restaurant_id,
        'restaurant_name', 'Kamolon',
        'restaurant_slug', 'kamolon-b87695',
        'branch_id', v_branch_id,
        'email_verified', true
      ),
      updated_at = now()
    WHERE email = 'demo@plately.app' OR id = v_user_id;
  ELSE
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      'demo@plately.app',
      v_enc_pass,
      now(),
      jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email'),
        'role', 'owner',
        'staff_role', 'owner',
        'restaurant_id', v_restaurant_id,
        'restaurant_name', 'Kamolon',
        'restaurant_slug', 'kamolon-b87695',
        'branch_id', v_branch_id
      ),
      jsonb_build_object(
        'name', 'Demo Manager',
        'display_name', 'Demo Manager',
        'role', 'owner',
        'restaurant_id', v_restaurant_id,
        'restaurant_name', 'Kamolon',
        'restaurant_slug', 'kamolon-b87695',
        'branch_id', v_branch_id,
        'email_verified', true
      ),
      now(),
      now(),
      '',
      ''
    );
  END IF;

  -- 2. Upsert into public.users for Plately.app consumer mobile
  INSERT INTO public.users (
    id,
    email,
    display_name,
    username,
    onboarding_done,
    household_size,
    daily_calorie_goal,
    dietary_tags,
    dietary_preferences,
    allergies,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    'demo@plately.app',
    'Demo Manager',
    'demo',
    true,
    2,
    2000,
    '{}',
    '{}',
    '{}',
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name = 'Demo Manager',
    username = 'demo',
    onboarding_done = true,
    updated_at = now();

  -- 3. Upsert into public.staff for Plately.workshop merchant OS
  INSERT INTO public.staff (
    user_id,
    restaurant_id,
    branch_id,
    role,
    display_name,
    email,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_restaurant_id,
    v_branch_id,
    'owner',
    'Demo Manager',
    'demo@plately.app',
    true,
    now(),
    now()
  )
  ON CONFLICT (user_id, restaurant_id) DO UPDATE SET
    role = 'owner',
    display_name = 'Demo Manager',
    branch_id = v_branch_id,
    is_active = true,
    updated_at = now();

  -- 4. Seed Kamolon Menu Items if not present
  IF NOT EXISTS (SELECT 1 FROM public.menu_items WHERE restaurant_id = v_restaurant_id) THEN
    INSERT INTO public.menu_items (
      restaurant_id,
      name,
      description,
      price,
      category,
      is_available,
      calories,
      tags,
      sort_order,
      is_featured,
      prep_time_minutes
    ) VALUES
      (
        v_restaurant_id,
        'To''y Oshi (Wedding Plov)',
        'Signature Tashkent wedding plov slow-cooked with tender beef, lamb, yellow carrots, chickpeas, raisins, and quail egg.',
        48000,
        'Main',
        true,
        780,
        ARRAY['bestseller', 'national', 'signature'],
        1,
        true,
        15
      ),
      (
        v_restaurant_id,
        'Tandir Somsa (Tandoor Samosa)',
        'Crispy flaky clay-oven baked pastry loaded with hand-minced spiced beef, sweet onions, and melted tail fat.',
        15000,
        'Pastry',
        true,
        320,
        ARRAY['hot', 'crispy', 'popular'],
        2,
        true,
        10
      ),
      (
        v_restaurant_id,
        'Qo''y Go''shti Shashlik (Lamb Kebab)',
        'Succulent skewers of tender marinated lamb cubes grilled over natural charcoal, served with vinegar-herb onions.',
        26000,
        'Grill',
        true,
        450,
        ARRAY['bbq', 'charcoal', 'grill'],
        3,
        true,
        20
      ),
      (
        v_restaurant_id,
        'Qovurma Lag''mon (Fried Lagman)',
        'Chewy hand-stretched noodles stir-fried in a hot wok with beef slivers, bell peppers, garlic greens, and rich spices.',
        42000,
        'Main',
        true,
        620,
        ARRAY['noodles', 'spicy', 'comfort'],
        4,
        false,
        18
      ),
      (
        v_restaurant_id,
        'Achichuk Salad',
        'Paper-thin Tashkent tomatoes, sweet sweet onions, crushed chili pepper, and fresh purple basil.',
        14000,
        'Salad',
        true,
        95,
        ARRAY['fresh', 'traditional', 'vegan'],
        5,
        false,
        5
      ),
      (
        v_restaurant_id,
        'Samarkand Ko''k Choy (Green Tea)',
        'Fragrant No. 95 Uzbek green tea served in an authentic porcelain teapot with fresh lemon slice and mint sprig.',
        12000,
        'Beverages',
        true,
        0,
        ARRAY['tea', 'traditional', 'refreshing'],
        6,
        false,
        5
      );
  END IF;

  -- 5. Seed Inventory Items for user's Living Shelf if not present
  IF NOT EXISTS (SELECT 1 FROM public.inventory_items WHERE user_id = v_user_id) THEN
    INSERT INTO public.inventory_items (
      user_id,
      ingredient_id,
      quantity,
      unit,
      item_state,
      location,
      source,
      purchase_date,
      computed_expiry
    ) VALUES
      (v_user_id, 'ab0e2326-0391-4f00-912c-e93ea383e613', 10, 'piece', 'opened', 'fridge', 'manual', CURRENT_DATE, CURRENT_DATE + INTERVAL '14 days'),
      (v_user_id, '574a087a-c223-4419-a4b7-dbd9ac8f8bde', 1, 'piece', 'opened', 'fridge', 'manual', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days'),
      (v_user_id, '6da58018-9bb8-4c01-8ebf-5a40ec80cdcf', 4, 'piece', 'opened', 'fridge', 'camera', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days'),
      (v_user_id, '55140b39-cd86-413b-985e-b9c2bad62799', 3, 'piece', 'opened', 'pantry', 'manual', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days');
  END IF;

END $$;
