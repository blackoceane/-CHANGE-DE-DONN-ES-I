# ECHANGE-DE-DONNEES-I

## Description du projet
Ce projet consiste en la création d'un serveur de stockage de fichiers sécurisé via une API REST. Il permet aux utilisateurs authentifiés de téléverser des fichiers, de les protéger par mot de passe et de transformer leur contenu (via des filtres textuels). Le système utilise une persistance de données en format JSON et une interface de galerie HTML dynamique.

## Fonctionnalités
- **Authentification Basic HTTP** : Système de connexion sécurisé avec hachage SHA-256 des mots de passe pour protéger l'accès à l'API.
- **Galerie Web** : Interface front-end simple permettant de visualiser la liste des fichiers, d'identifier ses propres fichiers et d'accéder aux fichiers protégés via un prompt de mot de passe.
- **Upload** : Téléversement de fichiers avec génération d'UUID uniques.
- **Transformation** : Application de filtres  au contenu textuel lors de la création.
- **Protection** : Possibilité d'ajouter, modifier ou retirer un mot de passe sur un fichier spécifique .
- **Suppression** : Retrait définitif des fichiers par l'utilisateur  propriétaire.

## Objectifs

- **Sécurisation des données** : Garantir que seul le propriétaire d'un fichier peut le modifier ou le supprimer.
- **Manipulation d'API REST** : Implémenter les méthodes standard (GET, POST, PATCH, DELETE) avec les codes de statut HTTP appropriés (201, 204, 403, 404).
- **Persistance légère** : Gérer la lecture et l'écriture asynchrone dans un fichier JSON servant de base de données.

 ## Problemes
 - Difficultée d éxecuter plusieurs filtres sur un fichier reçu

 -------------------------------------------------------------------------------------------------------------------------------
 CONÇU LE 05 DECEMBRE 2025 - 22 DECEMBRE 2025
