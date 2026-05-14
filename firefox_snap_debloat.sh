#!/usr/bin/env bash
set -euo pipefail

echo "Writing Firefox system policies..."

sudo mkdir -p /etc/firefox/policies

sudo tee /etc/firefox/policies/policies.json >/dev/null <<'JSON'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisableFirefoxAccounts": true,
    "DisableFirefoxScreenshots": true,
    "NoDefaultBookmarks": true,
    "OfferToSaveLogins": false,
    "SearchSuggestEnabled": false,
    "UserMessaging": {
      "ExtensionRecommendations": false,
      "FeatureRecommendations": false,
      "UrlbarInterventions": false,
      "SkipOnboarding": true,
      "MoreFromMozilla": false,
      "FirefoxLabs": false
    },
    "Preferences": {
      "browser.aboutwelcome.enabled": {
        "Value": false,
        "Status": "locked"
      },
      "browser.newtabpage.activity-stream.showSponsored": {
        "Value": false,
        "Status": "locked"
      },
      "browser.newtabpage.activity-stream.showSponsoredTopSites": {
        "Value": false,
        "Status": "locked"
      },
      "browser.newtabpage.activity-stream.feeds.section.topstories": {
        "Value": false,
        "Status": "locked"
      },
      "browser.urlbar.sponsoredTopSites": {
        "Value": false,
        "Status": "locked"
      },
      "browser.urlbar.quicksuggest.enabled": {
        "Value": false,
        "Status": "locked"
      },
      "browser.urlbar.suggest.quicksuggest.sponsored": {
        "Value": false,
        "Status": "locked"
      },
      "browser.urlbar.suggest.quicksuggest.nonsponsored": {
        "Value": false,
        "Status": "locked"
      },
      "datareporting.policy.dataSubmissionEnabled": {
        "Value": false,
        "Status": "locked"
      },
      "datareporting.healthreport.uploadEnabled": {
        "Value": false,
        "Status": "locked"
      },
      "toolkit.telemetry.enabled": {
        "Value": false,
        "Status": "locked"
      },
      "toolkit.telemetry.archive.enabled": {
        "Value": false,
        "Status": "locked"
      },
      "toolkit.telemetry.unified": {
        "Value": false,
        "Status": "locked"
      }
    }
  }
}
JSON

echo "Writing Firefox Snap profile user.js preferences..."

PROFILE_ROOT="$HOME/snap/firefox/common/.mozilla/firefox"

if [[ -d "$PROFILE_ROOT" ]]; then
    find "$PROFILE_ROOT" -maxdepth 1 -type d \( -name "*.default*" -o -name "*.release*" \) | while read -r profile; do
        user_js="$profile/user.js"

        if [[ -f "$user_js" ]]; then
            cp "$user_js" "$user_js.bak.$(date +%Y%m%d-%H%M%S)"
        fi

        cat > "$user_js" <<'PREFS'
// Firefox Snap debloat preferences

user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);

user_pref("browser.urlbar.sponsoredTopSites", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);

user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.unified", false);

user_pref("app.shield.optoutstudies.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.tabs.firefox-view", false);
PREFS

        echo "Updated: $user_js"
    done
else
    echo "Firefox Snap profile directory not found yet:"
    echo "  $PROFILE_ROOT"
    echo "Start Firefox once, then rerun this script to create per-profile user.js files."
fi

echo
echo "Done."
echo "Restart Firefox, then open about:policies to verify policies are active."
