## Handle raw data
* MBMF_parse_data.ipynb takes the raw data (MBMF_raw_data.txt) and and creates data constructed for both the logistics regression analysis and the RL computational modelling. This creates:
* MBMF_dataForLogisticReg.csv - a file for the logistic regression analysis.
* MBMF_data_for_RL_model.csv - a file for the RL computational modeling. 

## Computational modelling
* MBMF_run_comp_model.R will run the stan model and some model QA, save the model and assemble a csv file with the parameters extracted for each subject for further analyses. The file is named: MBMF_RL_model_extracted_parameters.csv.
<br></br>

## Note on handling raw data
* In the main analysis script file (../Habit_app_MAIN_analysis.R) the files MBMF_dataForLogisticReg.csv and MBMF_RL_model_extracted_parameters.csv are used for the main analyses involving the two-step task data (and the habit app data).
