# BookStore App — Version Guide

Three versions of the application, each with visible frontend and backend differences.

---

## Version Overview

| Version | Frontend Theme | Backend Response | Changes |
|---------|---------------|-----------------|---------|
| `1.0.0` | 🔵 Blue | `...v1.0.0` | Baseline |
| `2.0.0` | 🔴 Red | `...v2.0.0` | Red theme update |
| `3.0.0` | 🟣 Purple | `...v3.0.0` | Purple theme  |

> To build a specific version, update `src/frontend/src/pages/Home.jsx` (banner color + version label) and `src/backend/index.js` (response string) to match the tag.

## set-version.sh

Instead of editing files manually, use the [`set-version.sh`](./set-version.sh) script from the project root:

```bash
./src/set-version.sh <version> <color>

# Examples:
./src/set-version.sh 1.0.0 blue
./src/set-version.sh 2.0.0 red
./src/set-version.sh 3.0.0 purple
```

The script auto-detects the current version/color, updates all relevant files in one shot, and prints the docker build commands to run next.

**To add a new version** (e.g. `4.0.0` with green theme):
1. Add a new `green` case in the `case $COLOR` block of `set-version.sh` with the Tailwind color values
2. Run `./src/set-version.sh 4.0.0 green`
3. Add the new version row to the Version Overview table above

---

## Frontend Screenshots

<table>
<tr>
<td align="center"><strong>v1.0.0 — Blue</strong></td>
<td align="center"><strong>v2.0.0 — Red</strong></td>
<td align="center"><strong>v3.0.0 — Purple</strong></td>
</tr>
<tr>
<td><img src="../docs/assets/apps/app-v1-frontend.png"/></td>
<td><img src="../docs/assets/apps/app-v2-frontend.png"/></td>
<td><img src="../docs/assets/apps/app-v3-frontend.png"/></td>
</tr>
</table>

## Backend Screenshots

<table>
<tr>
<td align="center"><strong>v1.0.0</strong></td>
<td align="center"><strong>v2.0.0</strong></td>
<td align="center"><strong>v3.0.0</strong></td>
</tr>
<tr>
<td><img src="../docs/assets/apps/app-v1-backend.png"/></td>
<td><img src="../docs/assets/apps/app-v2-backend.png"/></td>
<td><img src="../docs/assets/apps/app-v3-backend.png"/></td>
</tr>
</table>

---