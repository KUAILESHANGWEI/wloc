#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# This is the only place where the upstream repository is intentionally kept.
UPSTREAM_REPO="${UPSTREAM_REPO:-Yu9191/wloc}"
TARGET_REPO="${TARGET_REPO:-${GITHUB_REPOSITORY:-KUAILESHANGWEI/wloc}}"

command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }

release_json="$(gh api "repos/${UPSTREAM_REPO}/releases/latest")"
tag="$(jq -r '.tag_name' <<<"${release_json}")"
name="$(jq -r '.name // .tag_name' <<<"${release_json}")"
prerelease="$(jq -r '.prerelease' <<<"${release_json}")"

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

gh release download "${tag}" --repo "${UPSTREAM_REPO}" --dir "${work_dir}"

# Localize text assets before publishing. Binary assets are copied byte-for-byte.
while IFS= read -r -d '' asset; do
  if grep -Iq . "${asset}"; then
    TARGET_REPO="${TARGET_REPO}" perl -0pi -e '
      my $target = $ENV{TARGET_REPO};
      s{https://raw\.githubusercontent\.com/Yu9191/wloc}{"https://raw.githubusercontent.com/" . $target}ge;
      s{https://github\.com/Yu9191/wloc}{"https://github.com/" . $target}ge;
      s{https://wloc-pages\.pages\.dev/?}{"https://github.com/" . $target}ge;
      s{https://wloc-spoofer\.wloc\.workers\.dev/?}{"https://github.com/" . $target}ge;
      s{https://www\.icloud\.com/shortcuts/a82717d8fdad4e6280866fcf911173f7}{"https://github.com/" . $target . "/releases/latest/download/WLOC-Set-Location.shortcut"}ge;
      s{https://www\.icloud\.com/shortcuts/f42632d406504f24a2cd163af4fe012f}{"https://github.com/" . $target . "/releases/latest/download/WLOC-Clear-Location.shortcut"}ge;
    ' "${asset}"
  fi
done < <(find "${work_dir}" -type f -print0)

notes="Automated isolated mirror of the ${tag} release. Assets are copied from the configured upstream source and project-owned links are rewritten to https://github.com/${TARGET_REPO}."

if gh release view "${tag}" --repo "${TARGET_REPO}" >/dev/null 2>&1; then
  gh release edit "${tag}" --repo "${TARGET_REPO}" --title "${name}" --notes "${notes}"
else
  release_args=("${tag}" --repo "${TARGET_REPO}" --target main --title "${name}" --notes "${notes}")
  if [[ "${prerelease}" == "true" ]]; then
    release_args+=(--prerelease)
  fi
  gh release create "${release_args[@]}"
fi

assets=()
while IFS= read -r -d '' asset; do
  assets+=("${asset}")
done < <(find "${work_dir}" -type f -print0)
if ((${#assets[@]})); then
  gh release upload "${tag}" "${assets[@]}" --repo "${TARGET_REPO}" --clobber
fi

signed_shortcuts=("${root_dir}"/shortcuts/signed/*.shortcut)
if [[ -e "${signed_shortcuts[0]}" ]]; then
  gh release upload "${tag}" "${signed_shortcuts[@]}" --repo "${TARGET_REPO}" --clobber
fi

echo "Synced ${#assets[@]} assets for ${tag} to ${TARGET_REPO}"
