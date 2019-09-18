Bash: transac
=============

```
 Followanalytics transactional pushes
 ------------------------------------

 fa_transac.sh login USER_IDENTIFIER
   login USER_IDENTIFIER into FA SSO, retrieve your AUTH_TOKEN (password read from STDIN)

 fa_transac.sh csv2json CAMPAIGN_IDENTIFIER.csv
   convert csv named as campaign_identifier, to a ready to push json file
   The CSV first line MUST be "user", then the variables keynames

 fa_transac.sh push AUTH_TOKEN -
   push transac messages defined in json on STDIN using AUTH_TOKEN as identification

 Note: commands needed in PATH: which, sed, curl
```

Logic
-----

0) If not done yet, fetch your `AUTH_TOKEN` https://dev.followanalytics.com/platform-apis/api-overview/#authentication
1) Prepare your JSON file accordinig to https://dev.followanalytics.com/platform-apis/campaigns/#body-parameters_2 (see command `csv2json` to help you)
2) Trigger the pushes batch https://dev.followanalytics.com/platform-apis/campaigns/#send-a-batch-of-transactional-messages

Facultative: fetch the status for the batch: https://dev.followanalytics.com/platform-apis/campaigns/#retrieve-a-sending-report

Best practices
----------------

It's recommanded to login only once per day, or after 401 responses.

Command `csv2json`
-------------------

Helper command to convert a CSV to a valid JSON for command `push`

### CSV

The CSV filename MUST be `FACMPGN_EXaMpLeoAvDJJuhpOP.csv`, so: your targeted campaign identifier with `.csv` extension
As explained in the banner, the first line (header) MUST be `user` then the variables keys defined into your transactionnal campaign.
If your transactional campaign defined the variables `name`, `position` and `localisation`, your header will be:

```
user,name,position,localisation
```

Chaining
--------

You can of course chain the calls. If in your current directory you have a valid csv file named `FACMPGN_EXaMpLeoAvDJJuhpOP.csv` and your AUTH_TOKEN is `MyAuthToken`, you can call:

```
   ./fa_transac.sh csv2json FACMPGN_EXaMpLeoAvDJJuhpOP.csv | ./fa_transac.sh push MyAuthToken
```

