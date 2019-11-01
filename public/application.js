$(document).ready(function() {
    $('#filesystems').DataTable({
        columnDefs: [
            { type: "file-size", orderSequence: ["desc","asc"], targets: 3 },
            { type: "formatted-num", orderSequence: ["desc","asc"], targets: 4 }
        ]
    });
} );

$(document).ready(function() {
    $('#user-quotas').DataTable({
        columnDefs: [
            { type: "file-size", orderSequence: ["desc","asc"], targets: 1 },
            { type: "formatted-num", orderSequence: ["desc","asc"], targets: 3 }
        ],
        order: [[1, "desc"]]
    });
} );
