#!/bin/bash
# Bascule le site en mode « app disponible » — à lancer le jour où Apple approuve.
# Usage : ./launch.sh          (puis vérifier, commit, push)
set -euo pipefail
cd "$(dirname "$0")"

URL="https://apps.apple.com/fr/app/id6786656462"

# Garde-fou : vérifier que l'app est bien en ligne avant de basculer le site.
code=$(curl -s -o /dev/null -w "%{http_code}" -L "$URL")
if [ "$code" != "200" ]; then
  echo "⚠️  La fiche App Store répond $code — l'app n'a pas l'air encore en ligne."
  echo "    Réessaie quand tu as reçu le mail « Ready for Distribution »."
  echo "    (Pour forcer quand même : FORCE=1 ./launch.sh)"
  [ "${FORCE:-0}" = "1" ] || exit 1
fi

before=$(grep -c "Bientôt sur l'App Store" index.html || true)

perl -i -pe "
  s{Bientôt sur l'App Store\\.}{Disponible sur l'App Store.}g;                       # meta description
  s{<a class=\"cta-sm\" href=\"#download\">App Store</a>}{<a class=\"cta-sm\" href=\"$URL\">App Store</a>};
  s{<a class=\"cta\" href=\"#download\"><span class=\"live\"></span> Bientôt sur l'App Store</a>}{<a class=\"cta\" href=\"$URL\"><span class=\"live\"></span> Télécharger sur l'App Store</a>};
  s{Bientôt sur l'App Store<span}{Disponible sur l'App Store<span};                  # H2 section finale
  s{Velk arrive sur iPhone — et toutes les fonctionnalités seront <strong>gratuites pendant le lancement</strong>}{Velk est disponible sur iPhone — toutes les fonctionnalités sont <strong>gratuites pendant le lancement</strong>};
  s{<a class=\"cta\" href=\"mailto:[^\"]*\"><span class=\"live\"></span> Être prévenu au lancement</a>}{<a class=\"cta\" href=\"$URL\"><span class=\"live\"></span> Télécharger Velk</a>};
  s{\"operatingSystem\": \"iOS\",}{\"operatingSystem\": \"iOS\",\n    \"installUrl\": \"$URL\",};   # JSON-LD
" index.html

after=$(grep -c "Bientôt sur l'App Store" index.html || true)
links=$(grep -c "apps.apple.com/fr/app/id6786656462" index.html || true)

echo "✓ Bascule faite : « Bientôt » restants : $after (avant : $before) · liens App Store posés : $links (attendu : 4)"
echo
echo "Vérifie le rendu :  open index.html"
echo "Puis mets en ligne : git add -A && git commit -m 'launch: app disponible, liens App Store' && git push origin main"
