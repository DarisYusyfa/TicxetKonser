/*
  # Concert Website Schema

  1. New Tables
    - concerts
      - Basic concert information including name, date, venue, description, image
      - Pricing and ticket types
    - tickets
      - Ticket information and status
      - Links to concerts and users
    - orders
      - Order tracking and payment status
    - users_profiles
      - Extended user profile information

  2. Security
    - RLS policies for all tables
    - Secure access patterns for tickets and orders
*/

-- Create tables
CREATE TABLE concerts (
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

CREATE TABLE ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  concert_id uuid REFERENCES concerts(id),
  name text NOT NULL,
  price decimal NOT NULL,
  quantity_available integer NOT NULL,
  quantity_sold integer DEFAULT 0,
  benefits text[],
  created_at timestamptz DEFAULT now()
);

CREATE TABLE orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  total_amount decimal NOT NULL,
  status text DEFAULT 'pending',
  payment_intent_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id),
  ticket_type_id uuid REFERENCES ticket_types(id),
  user_id uuid REFERENCES auth.users(id),
  status text DEFAULT 'pending',
  qr_code text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE users_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  full_name text,
  phone text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE concerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Concerts policies
CREATE POLICY "Anyone can view concerts"
  ON concerts FOR SELECT
  TO public
  USING (true);

-- Ticket types policies
CREATE POLICY "Anyone can view ticket types"
  ON ticket_types FOR SELECT
  TO public
  USING (true);

-- Orders policies
CREATE POLICY "Users can view their own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Tickets policies
CREATE POLICY "Users can view their own tickets"
  ON tickets FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users profiles policies
CREATE POLICY "Users can view their own profile"
  ON users_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON users_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);