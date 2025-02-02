/*
  # Concert Ticketing System Schema
  
  Creates core tables and security policies for the concert ticketing system
*/

-- Create base tables first
DO $$ BEGIN

-- Concerts table
CREATE TABLE IF NOT EXISTS concerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  artist text NOT NULL,
  date timestamptz NOT NULL,
  venue text NOT NULL,
  description text,
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Ticket types table
CREATE TABLE IF NOT EXISTS ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  concert_id uuid REFERENCES concerts(id),
  name text NOT NULL,
  price decimal NOT NULL,
  quantity_available integer NOT NULL,
  quantity_sold integer DEFAULT 0,
  benefits text[],
  created_at timestamptz DEFAULT now()
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  total_amount decimal NOT NULL,
  status text DEFAULT 'pending',
  payment_intent_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tickets table
CREATE TABLE IF NOT EXISTS tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id),
  ticket_type_id uuid REFERENCES ticket_types(id),
  user_id uuid REFERENCES auth.users(id),
  status text DEFAULT 'pending',
  qr_code text,
  created_at timestamptz DEFAULT now()
);

-- User profiles table
CREATE TABLE IF NOT EXISTS users_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  full_name text,
  phone text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

END $$;

-- Enable RLS
DO $$ BEGIN
  ALTER TABLE concerts ENABLE ROW LEVEL SECURITY;
  ALTER TABLE ticket_types ENABLE ROW LEVEL SECURITY;
  ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
  ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
  ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;
END $$;

-- Create basic policies
DO $$ BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Anyone can view concerts" ON concerts;
  DROP POLICY IF EXISTS "Anyone can view ticket types" ON ticket_types;
  DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
  DROP POLICY IF EXISTS "Users can create their own orders" ON orders;
  DROP POLICY IF EXISTS "Users can view their own tickets" ON tickets;
  DROP POLICY IF EXISTS "Users can view their own profile" ON users_profiles;
  DROP POLICY IF EXISTS "Users can update their own profile" ON users_profiles;

  -- Recreate policies
  CREATE POLICY "Anyone can view concerts" ON concerts
    FOR SELECT TO public
    USING (true);

  CREATE POLICY "Anyone can view ticket types" ON ticket_types
    FOR SELECT TO public
    USING (true);

  CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

  CREATE POLICY "Users can create their own orders" ON orders
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

  CREATE POLICY "Users can view their own tickets" ON tickets
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

  CREATE POLICY "Users can view their own profile" ON users_profiles
    FOR SELECT TO authenticated
    USING (auth.uid() = id);

  CREATE POLICY "Users can update their own profile" ON users_profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
END $$;