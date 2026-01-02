-- 1. Création de la base pour Keycloak (si non existante)
SELECT 'CREATE DATABASE keycloak' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak')\gexec

-- 2. Connexion à la base de l'application
\c app_db

-- 3. Création de la table dans le schéma public
CREATE TABLE IF NOT EXISTS public.users (
    id serial PRIMARY KEY,
    name text NOT NULL,
    email text UNIQUE NOT NULL
);

-- 4. Nettoyage et insertion des données
TRUNCATE TABLE public.users;
INSERT INTO public.users (name, email) VALUES
('brian', 'lauren.etoundi@saintjeaningenieur.org'),
('axel', 'merlin.essama@saintjeaningenieur.org'),
('chris', 'chris.nanfack@saintjeaningenieur.org');

-- --- CONFIGURATION DES RÔLES POUR POSTGREST ---

-- Création des rôles sans droit de connexion (utilisés par PostgREST)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_user') THEN
    CREATE ROLE web_user NOLOGIN;
  END IF;
END $$;

-- Autoriser l'utilisateur de connexion (admin) à changer d'identité pour ces rôles
GRANT anon TO admin;
GRANT web_user TO admin;

-- --- PERMISSIONS SUR LE SCHÉMA ---
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO web_user;

-- --- PERMISSIONS SUR LES TABLES ---

-- Rôle Anonyme : On lui donne le droit de lecture pour corriger l'erreur 404 lors des tests
-- (Une fois en production, vous pourrez retirer ce droit si vous voulez forcer le login)
GRANT SELECT ON public.users TO anon;

-- Rôle Authentifié : Droit de lecture complet
GRANT SELECT ON public.users TO web_user;

-- Important : Donner accès à la séquence pour les futurs inserts
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO web_user;
