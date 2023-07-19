## This is the Space Gold (real-world free-operant) app code (frontend code).
### Notes:
* The task is comprehensivly described in the paper - A novel smartphone app for experimental habit induction in humans (Gera et al.)
* The app is designed as a progressive web application (PWA) and is compatible with both iphones and andorid-based smartphones.
* It is designed to be connected with a mongoDB database and to use websockets for fast communication.

### To use it: 
* Look for the placeholder ROOT_DOMAIN in settings.js and create_subject_keycodes_and_manifests.py and replace with the root domain intend to use.
* Run create_subject_keycodes_and_manifests.py to create subject ID codes, links and related files.
* The app needs to be connected with a backend code and a mogoDB database (or you can adjust it to use any other preferred alternative).

