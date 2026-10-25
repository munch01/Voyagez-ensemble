# Cap — feuille de route de voyage

Application web en français, prévue pour Firefox récent. Elle permet de gérer des voyages partagés, de planifier des étapes avec heures de début et de fin, de les placer sur une carte OpenStreetMap et d’associer des billets ou réservations privés à chaque étape.

## Mise en service

1. Créez un projet sur [Supabase](https://supabase.com/) et attendez la fin de son initialisation.
2. Dans **SQL Editor**, exécutez le contenu de [`supabase.sql`](./supabase.sql). Cela crée les tables, les règles d’accès et le bucket privé de pièces jointes.
3. Dans **Project Settings → API**, copiez l’URL du projet et la clé publique **anon** (ou **publishable**). Ne mettez jamais une clé `service_role` dans cette application.
4. Ouvrez `index.html` dans Firefox, sélectionnez **Configurer Supabase**, puis renseignez ces deux valeurs. La configuration est conservée dans le stockage local du navigateur.
5. Créez un compte. Selon la configuration d’authentification du projet, il faudra confirmer l’adresse e-mail avant de se connecter. Créez un voyage depuis **Voyage & partage**.
6. Pour partager le voyage, chaque participant crée son compte Cap avec l’adresse e-mail invitée, puis accepte l’invitation dans **Voyage & partage**. Cap n’envoie pas de courriel d’invitation automatique : prévenez la personne séparément. Le partage fonctionne entre personnes qui utilisent la même version hébergée de l’application et le même projet Supabase.

Pour que les données se mettent à jour immédiatement chez les autres participants, activez la réplication Realtime dans Supabase pour les tables `trips`, `stops` et `stop_attachments` (**Database → Publications → supabase_realtime**). Sans cela, l’application actualise le voyage automatiquement toutes les 20 secondes.

## Utilisation et limites

- Une étape contient un nom, un lieu/adresse, les heures de début et de fin, des notes et plusieurs fichiers PDF ou images (20 Mo maximum chacun).
- Les fichiers sont dans un bucket Supabase **privé**; les liens de consultation sont temporaires. Les règles RLS limitent les voyages, étapes et fichiers aux membres connectés du voyage.
- Une adresse est recherchée via le service public Nominatim d’OpenStreetMap pour obtenir ses coordonnées. La carte et ce service nécessitent une connexion Internet et sont soumis aux conditions d’utilisation de leurs fournisseurs.
- Le HTML charge Leaflet, Supabase JS et les tuiles de carte depuis leurs CDN. Pour partager l’application, hébergez `index.html` sur un hébergement statique HTTPS accessible aux participants; ne partagez pas le fichier sur lequel un seul navigateur conserverait les identifiants de projet.
- Google Drive n’est pas utilisé comme base de synchronisation. Il pourra être ajouté comme export ou sauvegarde distincte.

## Protection des données

Utilisez exclusivement la clé publique anon/publishable dans le navigateur; la clé `service_role` contournerait les règles d’accès et ne doit jamais être exposée. Vérifiez les règles d’accès avant d’y déposer des documents sensibles. Les utilisateurs et administrateurs du projet Supabase peuvent administrer les données du projet.
