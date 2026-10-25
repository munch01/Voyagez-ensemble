# Voyagez ensemble — feuille de route de voyage

Application web en français, prévue pour Firefox récent. Elle permet de gérer des voyages partagés, de planifier des étapes avec heures de début et de fin, de les placer sur une carte OpenStreetMap et d’associer des billets ou réservations privés à chaque étape.

## Mise en service

1. Créez un projet sur [Supabase](https://supabase.com/) et attendez la fin de son initialisation.
2. Dans **SQL Editor**, exécutez le contenu de [`supabase.sql`](./supabase.sql). Cela crée les tables, les règles d’accès et le bucket privé de pièces jointes.
3. Dans **Project Settings → API**, copiez l’URL du projet et la clé publique **anon** (ou **publishable**). Ne mettez jamais une clé `service_role` dans cette application.
4. La configuration publique du projet est préremplie dans l’application. La clé `publishable` est destinée au navigateur et est protégée par les politiques RLS du script SQL; n’utilisez jamais une clé secrète ou `service_role`.
5. Ouvrez l’application sur son adresse HTTPS, puis créez un compte. Selon la configuration d’authentification du projet, il faudra confirmer l’adresse e-mail avant de se connecter. Cliquez sur le **+** à côté de **Mes voyages** pour créer un voyage avec son nom, sa destination, ses dates et les e-mails des participants.
6. Les informations du voyage restent modifiables dans **Informations et participants** sur la feuille de route. Pour partager le voyage, chaque participant crée son compte avec l’adresse e-mail invitée, puis accepte l’invitation depuis la feuille de route. L’application n’envoie pas de courriel automatique : prévenez la personne séparément. Le partage fonctionne entre personnes qui utilisent la même version hébergée de l’application et le même projet Supabase.

Pour que les données se mettent à jour immédiatement chez les autres participants, activez la réplication Realtime dans Supabase pour les tables `trips`, `stops` et `stop_attachments` (**Database → Publications → supabase_realtime**). Sans cela, l’application actualise le voyage automatiquement toutes les 20 secondes.

## Publication sur GitHub Pages

Le workflow [`.github/workflows/pages.yml`](./.github/workflows/pages.yml) publie automatiquement le site à chaque mise à jour de `main`. Dans GitHub, ouvrez **Settings → Pages**, choisissez **GitHub Actions** comme source, puis attendez la fin de l’exécution du workflow **Publish website** dans l’onglet **Actions**. Le site sera disponible à l’adresse `https://munch01.github.io/Voyagez-ensemble/`.

Pour autoriser l’inscription et le retour après confirmation de l’adresse e-mail, ajoutez cette adresse dans les URL autorisées du projet Supabase : **Authentication → URL Configuration**. Définissez aussi cette URL comme **Site URL**.

## Utilisation et limites

- Dans **Mes voyages**, chaque voyage se déplie pour afficher sa **Feuille de route**, les jours générés depuis ses dates, puis sa **Carte**. Sélectionnez un jour pour l’afficher dans la feuille de route.
- La feuille de route crée automatiquement une section par jour entre le départ et le retour du voyage, même si aucune étape n’est encore prévue.
- Une étape contient un nom, un lieu/adresse, les heures de début et de fin, des notes et plusieurs fichiers PDF ou images (20 Mo maximum chacun).
- Les fichiers sont dans un bucket Supabase **privé**; les liens de consultation sont temporaires. Les règles RLS limitent les voyages, étapes et fichiers aux membres connectés du voyage.
- Une adresse est recherchée via le service public Nominatim d’OpenStreetMap pour obtenir ses coordonnées. La carte et ce service nécessitent une connexion Internet et sont soumis aux conditions d’utilisation de leurs fournisseurs.
- Le HTML charge Flatpickr (calendriers en français), Leaflet, Supabase JS et les tuiles de carte depuis leurs CDN. Pour partager l’application, hébergez `index.html` sur un hébergement statique HTTPS accessible aux participants; ne partagez pas le fichier sur lequel un seul navigateur conserverait les identifiants de projet.
- Google Drive n’est pas utilisé comme base de synchronisation. Il pourra être ajouté comme export ou sauvegarde distincte.

## Protection des données

Utilisez exclusivement la clé publique anon/publishable dans le navigateur; la clé `service_role` contournerait les règles d’accès et ne doit jamais être exposée. Vérifiez les règles d’accès avant d’y déposer des documents sensibles. Les utilisateurs et administrateurs du projet Supabase peuvent administrer les données du projet.
