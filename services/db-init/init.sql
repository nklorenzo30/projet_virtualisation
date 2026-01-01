-- Création de la base pour Keycloak
CREATE DATABASE keycloak;

-- On bascule sur la base de l'application
\c app_db

-- Votre table users
CREATE TABLE public.users (
    id serial PRIMARY KEY,
    name text NOT NULL,
    email text UNIQUE NOT NULL
);

-- Insertion des données
INSERT INTO public.users (name, email) VALUES
('brian', 'lauren.etoundi@saintjeaningenieur.org'),
('axel', 'merlin.essama@saintjeaningenieur.org'),
('chris', 'chris.nanfack@saintjeaningenieur.org');

-- --- CONFIGURATION DES RÔLES (CORRECTION) ---

-- 1. On crée les rôles sans LOGIN (PostgREST les utilise comme identités de session)
DROP ROLE IF EXISTS anon;
DROP ROLE IF EXISTS web_user;
CREATE ROLE anon NOLOGIN;
CREATE ROLE web_user NOLOGIN;

-- 2. On autorise l'utilisateur 'admin' (celui du conteneur DB) à devenir ces rôles
GRANT anon TO admin;
GRANT web_user TO admin;

-- 3. Permissions sur le schéma et les tables
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO web_user;

-- Anon ne peut rien voir (sécurité)
-- Web_user peut lire la table users
GRANT SELECT ON public.users TO web_user;
