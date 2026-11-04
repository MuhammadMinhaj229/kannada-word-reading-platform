# Privacy and data handling

## Current design

- No cloud database is configured.
- No participant data is sent automatically to a server.
- Trial records are stored in the tablet browser's IndexedDB.
- The PWA uses study IDs and assessor IDs; avoid child names unless the approved protocol requires them.
- Export is assessor initiated and non-destructive.
- No analytics, advertising, tracking SDK or remote font/TTS dependency is required.

## Safeguards before field use

The research institution must approve the data controller, data retention period, local encryption approach, tablet custody, device-loss response, export destination, transfer channel, access control and deletion process. Browser-local IndexedDB is not automatically equivalent to encrypted institutional storage; do not treat it as sufficient protection without an endpoint-security assessment.

## REDCap boundary

The initial version exports locally for authorised import into the existing REDCap system. Do not embed REDCap project API tokens in the browser bundle. Automated synchronisation is a separate future project requiring a secure server-side design and approval from the REDCap administrator.
