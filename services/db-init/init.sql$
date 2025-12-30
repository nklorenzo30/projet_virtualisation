-- -------------------------------------------------------------
-- Création du rôle anonyme (aucun droit sur les tables)
-- -------------------------------------------------------------
DROP ROLE IF EXISTS anon;
CREATE ROLE anon NOINHERIT;
-- Pas de permissions, donc accès interdit sans JWT

-- -------------------------------------------------------------
-- Création du rôle Postgres pour les utilisateurs JWT
-- -------------------------------------------------------------
DROP ROLE IF EXISTS web_user;
CREATE ROLE web_user NOINHERIT LOGIN;

-- -------------------------------------------------------------
-- Création de la table users
-- -------------------------------------------------------------
DROP TABLE IF EXISTS public.users;
CREATE TABLE public.users (
    id serial PRIMARY KEY,
    name text NOT NULL,
    email text UNIQUE NOT NULL
);

-- -------------------------------------------------------------
-- Donner les permissions au rôle web_user
-- -------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO web_user;
GRANT SELECT ON public.users TO web_user;

-- Pour les futures tables, donner également les droits au rôle web_user
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO web_user;

-- -------------------------------------------------------------
-- Insertion des données d’exemple
-- -------------------------------------------------------------
INSERT INTO public.users (name, email) VALUES
('brian', 'lauren.etoundi@saintjeaningenieur.org'),
('axel', 'merlin.essama@saintjeaningenieur.org'),
('chris', 'chris.nanfack@saintjeaningenieur.org');

