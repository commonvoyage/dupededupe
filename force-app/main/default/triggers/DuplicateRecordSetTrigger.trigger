trigger DuplicateRecordSetTrigger on DuplicateRecordSet (after update) {
    List<DuplicateRecordSet> drsForDelete = new List<DuplicateRecordSet>();
    for (DuplicateRecordSet drs : (List<DuplicateRecordSet>) trigger.new) {
        if (drs.RecordCount == 1) {
            drsForDelete.add(drs);
        }
    }
    //delete drsForDelete;
}