-- Création de la base pour Keycloak
CREATE DATABASE keycloak;

-- On bascule sur la base de l'application (créée par la variable POSTGRES_DB)
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

-- Rôles pour PostgREST
CREATE ROLE anon NOINHERIT;
CREATE ROLE web_user NOINHERIT LOGIN;
GRANT USAGE ON SCHEMA public TO web_user;
GRANT SELECT ON public.users TO web_user;
