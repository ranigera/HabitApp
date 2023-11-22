
### Notes:
* Within the data folder some large files are zipped (they need to be extracted first in order to be used)
* **Habit_app_parse_data.ipynb** is used to parse the data. ***The data is already parsed and this file should not be run/used here.*** It works by communicating with a database on MongoDB (to reuse insert the credentials in mongoDB_stuff/mongo_DB_credentials.json); it cannot be run without the credentials and it was placed here to indicate how it should be used with new data.
* Two-step task data preperation for integration with the app data is done within the MBMD_prep folder (see details inside that folder). Running it is not required (but possible) as the necessary data was already parsed and available in data/MBMF (Nevertheless to have the stan model fit output object MBMF_prep/MBMF_run_comp_model.R need to be run).

### Files:
#### Habit_app_MAIN_analysis.R - Main analysis file.
#### Habit_app_response_plots.ipynb - used to a few of the plots (which are related to the number of entries).
