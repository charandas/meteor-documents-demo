this.Documents = new Meteor.Collection("documents");

this.Documents.allow({ 
    insert: (userId, doc) ->
        # only allow insertion if user logged in
        (!! userId)
    update: (userId, doc, fields) ->
        (doc.userId is userId and fields[0] in ['invitedUsers', 'title'])
    remove: (userId, doc) ->
        (doc.userId is userId)
})

Meteor.methods
  deleteDocument: (id) ->
    Documents.remove(id)
    ShareJS.model.delete(id) unless @isSimulation # ignore error