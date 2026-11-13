# Clareo — app iOS (App Store)

Wrapper iOS de https://clareogestion.fr. Utilise `SFSafariViewController` (vrai
moteur Safari) plutôt qu'une WebView classique : Google bloque la connexion
« Se connecter avec Google » dans les WebView intégrées, mais l'autorise dans
Safari View Controller — c'est l'équivalent iOS de la TWA Android.

Cette machine ne peut pas compiler l'app (macOS 12.7.6, ce MacBook Pro 2015 ne
peut pas passer à macOS 13+, et Apple n'accepte plus les apps compilées avec un
SDK aussi ancien). La compilation, la signature et l'envoi vers App Store
Connect se font via **GitHub Actions**, sur un vrai Mac récent dans le cloud —
voir `.github/workflows/`.

## Ce qui est déjà prêt
- Le projet Xcode (`Clareo.xcodeproj`, généré avec XcodeGen depuis `project.yml`).
- Le workflow `build.yml` : compile sans signature à chaque push (déjà vérifiable
  maintenant, aucun compte Apple nécessaire).
- Le workflow `release.yml` : archive, signe et envoie vers App Store Connect
  (déclenché manuellement, une fois les secrets ci-dessous configurés).
- `signing/clareo-distribution.csr` + `signing/clareo-distribution.key` : la
  demande de certificat et sa clé privée, déjà générées avec `openssl` (pas
  besoin d'Xcode pour cette étape). **Le fichier `.key` ne doit jamais être
  partagé ni commité** (il est dans `.gitignore`).

## Ce qu'il te reste à faire (étapes manuelles, dans l'ordre)

### 1. Créer le compte Apple Developer Program
Sur developer.apple.com/programs → 99 $ US/an, ton propre compte Apple, ton
propre paiement. Attends la validation (parfois 24-48h).

### 2. Enregistrer l'identifiant de l'app
Sur developer.apple.com/account → Identifiers → + → App IDs → App →
  - Bundle ID (explicite) : `fr.clareogestion.app`
  - Aucune capability particulière à cocher.

### 3. Créer le certificat de distribution à partir du CSR déjà préparé
Sur developer.apple.com/account → Certificates → + → **Apple Distribution** →
  - Quand il demande un CSR (« Certificate Signing Request »), upload le fichier
    `signing/clareo-distribution.csr` (déjà prêt dans ce dossier, pas besoin
    d'en générer un autre depuis Keychain Access).
  - Télécharge le certificat généré (`distribution.cer`).

Puis, pour fabriquer le `.p12` que GitHub Actions utilisera pour signer (à
exécuter sur n'importe quelle machine avec `openssl`, y compris celle-ci) :
```bash
cd clareo-ios/signing
openssl x509 -inform der -in distribution.cer -out distribution.pem
openssl pkcs12 -export \
  -inkey clareo-distribution.key \
  -in distribution.pem \
  -out clareo-distribution.p12 \
  -passout pass:CHOISIS_UN_MOT_DE_PASSE_ICI
```

### 4. Créer le profil de provisionnement App Store
Sur developer.apple.com/account → Profiles → + → **App Store Connect** (type
distribution) → choisir l'App ID `fr.clareogestion.app` → choisir le certificat
créé à l'étape 3 → télécharger le fichier `.mobileprovision`. Note son **nom
exact** (affiché dans le profil, par ex. "Clareo App Store").

### 5. Créer la clé API App Store Connect (pour l'envoi automatique)
Sur appstoreconnect.apple.com → Users and Access → Integrations → App Store
Connect API → + → rôle **App Manager** → télécharger le fichier `.p8` (⚠️
téléchargeable une seule fois) → noter le **Key ID** et l'**Issuer ID** affichés.

### 6. Ajouter les secrets sur le dépôt GitHub
Sur github.com/dede17x/clareo-ios → Settings → Secrets and variables → Actions
→ New repository secret, un par un :

| Nom du secret | Valeur |
|---|---|
| `IOS_DIST_CERTIFICATE_P12_BASE64` | `base64 -i clareo-distribution.p12 \| pbcopy` puis coller |
| `IOS_DIST_CERTIFICATE_PASSWORD` | le mot de passe choisi à l'étape 3 |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -i profil.mobileprovision \| pbcopy` puis coller |
| `IOS_PROVISIONING_PROFILE_NAME` | le nom exact du profil (étape 4) |
| `APPLE_TEAM_ID` | ton Team ID (visible sur developer.apple.com/account, en haut à droite) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` puis coller |
| `APP_STORE_CONNECT_KEY_ID` | le Key ID de l'étape 5 |
| `APP_STORE_CONNECT_ISSUER_ID` | l'Issuer ID de l'étape 5 |

### 7. Créer la fiche de l'app sur App Store Connect
appstoreconnect.apple.com → My Apps → + → New App → remplir bundle ID
(`fr.clareogestion.app`), nom, langue principale. (Je peux rédiger le texte de
la fiche — nom, description, mots-clés — si tu veux.)

### 8. Lancer l'envoi
Sur GitHub → onglet Actions → "Release to App Store Connect" → Run workflow.
Une fois terminé, la version apparaît dans App Store Connect sous TestFlight
puis peut être rattachée à une version pour soumission.

### 9. Soumettre pour revue
Dans App Store Connect : remplir captures d'écran, politique de confidentialité
(obligatoire), questionnaire de confidentialité ("App Privacy"), puis cliquer
**Submit for Review** — cette dernière action t'appartient, je ne peux pas la
faire à ta place.
