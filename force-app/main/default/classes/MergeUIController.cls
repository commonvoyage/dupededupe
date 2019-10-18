public with sharing class MergeUIController {

    @AuraEnabled(cacheable=true)
    public static List<Option> getObjectsForMerge(){
        Schema.DescribeSObjectResult contactDescribe = Contact.getSObjectType().getDescribe();
        Schema.DescribeSObjectResult accountDescribe = Account.getSObjectType().getDescribe();
        List<Option> options = new List<Option>{
            new Option(contactDescribe.getName(), contactDescribe.getLabel()),
            new Option(accountDescribe.getName(), accountDescribe.getLabel())
        };
        return options;
    }

    public class Option {
        @AuraEnabled public string label;
        @AuraEnabled public string value;

        public Option(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}
