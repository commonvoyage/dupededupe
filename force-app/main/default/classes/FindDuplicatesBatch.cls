public without sharing class FindDuplicatesBatch implements Database.Batchable<sObject> {
    private String dedupObject;
    private String whereClause;

    public FindDuplicatesBatch() {
        dedupObject = 'Contact';
    }
    public FindDuplicatesBatch(Schema.SObjectType objectType) {
        dedupObject = objectType.getDescribe().getName();
    }
    public FindDuplicatesBatch(Schema.SObjectType objectType, String optionalWhereClause) {
        dedupObject = objectType.getDescribe().getName();
        whereClause = optionalWhereClause;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM ' + dedupObject;
        if (String.isNotBlank(whereClause)) {
            query += ' ' + whereClause;
        } 

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> objects) {
        //FindDuplicates duplicates = new FindDuplicates(objects);
        //create DuplicateResults where they don't exist

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.optAllOrNone = false;

        //Database.update(objects, dml);
        new FindDuplicates().execute(objects);
    }

    public void finish(Database.BatchableContext BC) {}
}