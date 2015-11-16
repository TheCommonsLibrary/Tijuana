var LookupUserEvent = {
    subscribe: function(handler) {
        $('body').on('userLookup', function (e) {
            handler(e);
        });
    },

    publish: function(payload) {
        $('body').trigger($.Event('userLookup', payload));
    }
};
