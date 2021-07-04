# How to editing records with errors

The lists of records with errors and missed trees are [here](https://github.com/SCBI-ForestGEO/SCBImortality/tree/main/testthat/reports/requires_field_fix).

A summary of n errors by quadrat is [here](https://github.com/SCBI-ForestGEO/SCBImortality/blob/main/testthat/reports/quadrat_n_errors_summary.csv).

All fixes need to be done in FastField (unless this proves awful, in which case we can come up with an alternative). To send records back to FastField for editing, follow these steps:

1. Login to the [FFF's account](https://manage.fastfieldforms.com/Account/Login) (username ecoclimlab@gmail.com) and choose 'Legacy Portal' at bottom of left sidebar.

<img src="https://user-images.githubusercontent.com/6355854/124400940-2bce3f80-dcf4-11eb-8660-ec6004f38968.png" alt="drawing" width="300"/>


2. Go to 'Submissions' and in the 'Filters' section on the right select 'SCBI Mortality'
 <img width="1488" alt="image" src="https://user-images.githubusercontent.com/6355854/124400980-764fbc00-dcf4-11eb-9be2-d636b2082b87.png">

3. Add a filter - this can be the quadrat name from the drop down list: Quad/lookuplistpicker_1

<img width="540" alt="image" src="https://user-images.githubusercontent.com/6355854/124401087-79977780-dcf5-11eb-97c0-3c22ed179a93.png">

4. Use [SCBImortality/testthat/reports/quadrat_n_errors_summary.csv](https://github.com/SCBI-ForestGEO/SCBImortality/blob/main/testthat/reports/quadrat_n_errors_summary.csv) to identify quadrats with errors.  Apply the filter and you should have a list of the submissions for the quadrat (likely only 1 per quadrat)

<img width="328" alt="image" src="https://user-images.githubusercontent.com/6355854/124401532-fcb9cd00-dcf7-11eb-8bf4-00709d7665a9.png">

7. To the left of the submission there is a 'View' button with an arrow. Click on the arrow and 'Dispatch'
8. Type ecoclimlab@gmail.com in the 'Users' box, then click 'Dispatch'
9. Open the FFF's app on the iPad and open the Inbox to view the dispatched file. From there you can edit and resubmit and the submission should replace the original.