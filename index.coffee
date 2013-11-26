this.Documents = new Meteor.Collection("documents");

this.Documents.allow({ 
    insert: (userId, doc) ->
        # only allow insertion if user logged in
        (!! userId)
    update: (userId, doc, fields) ->
        (doc.userId is userId and fields[0] in ['invitedUsers', 'title', 'revokePending'])
    remove: (userId, doc) ->
        (doc.userId is userId)
})

Meteor.methods
  deleteDocument: (id) ->
    Documents.remove(id)
    ShareJS.model.delete(id) unless @isSimulation # ignore error

# Observe changes on documents, especially revokePending array property
if (Meteor.isClient)
    cursor = this.Documents.find()

    # watch the cursor for changes
    handle = cursor.observe({
      changed:  (doc) ->
        userId = Meteor.userId()
        Session.set('invitedUsers', doc.invitedUsers)
        
        if doc.userId is userId
            return
        
        if (Session.get('document') is doc._id) and (userId in doc.revokePending)          
            Session.set('document', null)
            Session.set('owner', "")
            Session.set('invitedUsers', [])
            $("#revokedModal").trigger("revokedEvent")
    })

# Observe changes on documents, especially revokePending array property
# Gracefully withdraw invitations, and clear out revokePending array
if (Meteor.isServer)
    cursor = this.Documents.find()

    # watch the cursor for changes
    handle = cursor.observe({

      changed:  (doc) ->
        unless doc.revokePending.length > 0
            return

        # Give 500 ms for clients to clear out their session variables before kicking them out
        Meteor.setTimeout (-> 
            Documents.update({_id: doc._id}, {$pullAll: {invitedUsers: doc.revokePending}})
            Documents.update({_id: doc._id}, {$pullAll: {revokePending: doc.revokePending}})
        )
        , 500
    })