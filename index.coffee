this.Documents = new Meteor.Collection("documents");

this.Documents.allow({ 
    insert: (userId, doc) ->
        # only allow insertion if user logged in
        (!! userId)
    update: (userId, doc, fields) ->
        if fields[0] == 'invitedUsers'
            return true

        return false
})

Meteor.methods
  deleteDocument: (id) ->
    Documents.remove(id)
    ShareJS.model.delete(id) unless @isSimulation # ignore error

  inviteOnDocument: (id, users) ->
    console.log(users[0])
    Documents.update({_id: id}, {$addToSet: {invitedUsers: users[0]}})