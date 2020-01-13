$(() => {
  $(document).ready(() => {
    if (document.getElementById('dt-mails')) {
      window.dt_conveyors = $('#dt-mails').DataTable({
        responsive: true,
        serverSide: true,
        searchDelay: 1000,
        processing: true,
        ajax: {
          url: "/inbox.json",
          before
          dataSrc: (result) => { return result.data }
        },
        // fnDrawCallback: (oSettings) => {
        //   window.initTooltip()
        //   setSelect2ForDatatableLength()
        // }
        language: translations,
        autoWidth: false,
        // order: [[0, "asc"]],
        columnDefs: [
          // {
          //   orderable: false,
          //   targets: [$('#dt-mails thead th').length - 1],
          // },
          {
            responsivePriority: 1,
            targets: 0,
          },
          {
            responsivePriority: 2,
            targets: $('#dt-mails thead th').length - 1,
          },
        ]
      })
    }
  })

  let translations = {
    "sEmptyTable": "Nenhum registro encontrado",
    "sInfo": "Mostrando de _START_ até _END_ de _TOTAL_ registros",
    "sInfoEmpty": "Mostrando 0 até 0 de 0 registros",
    "sInfoFiltered": "(Filtrados de _MAX_ registros)",
    "sInfoPostFix": "",
    "sInfoThousands": ".",
    "sLengthMenu": "_MENU_ resultados por página",
    "sLoadingRecords": "Carregando...",
    "sProcessing": `<span>Filtering...</span>`,
    "sZeroRecords": "Nenhum registro encontrado",
    "searchPlaceholder": 'Pesquisar...',
    "sSearch": "",
    "oPaginate": {
      "sNext": "Próximo",
      "sPrevious": "Anterior",
      "sFirst": "Primeiro",
      "sLast": "Último",
    },
    "oAria": {
      "sSortAscending": ": Ordenar colunas de forma ascendente",
      "sSortDescending": ": Ordenar colunas de forma descendente",
    },
  }
})