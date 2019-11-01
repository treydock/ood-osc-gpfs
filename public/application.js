$(document).ready(function() {
    $('#filesystems').DataTable({
        columnDefs: [
            { type: "file-size", targets: 3 }
        ]
    });
} );

$(document).ready(function() {
    $('#user-quotas').DataTable({
        columnDefs: [
            { type: "file-size", targets: 1 }
        ]
    });
} );
