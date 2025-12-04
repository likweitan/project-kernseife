sap.ui.define(
  [
    'sap/m/MessageBox',
    'sap/m/MessageToast',
    'sap/ui/unified/FileUploaderParameter'
  ],
  function (MessageBox, MessageToast, FileUploaderParameter) {
    'use strict';

    const _createImportController = (oExtensionAPI) => {
      let oImportDialog;
      let isFileUploadRequired = false;

      const setOkButtonEnabled = function (bOk) {
        oImportDialog && oImportDialog.getBeginButton().setEnabled(bOk);
      };

      const setDialogBusy = function (bBusy) {
        oImportDialog.setBusy(bBusy);
      };

      const closeDialog = function () {
        oImportDialog && oImportDialog.close();
      };

      const showError = function (sMessage) {
        MessageBox.error(sMessage || 'Upload failed');
      };

      const byId = function (sId) {
        return sap.ui.core.Fragment.byId('importDialog', sId);
      };

      const setFieldVisibility = function (id, visibility) {
        const label = byId('label' + id.charAt(0).toUpperCase() + id.slice(1));
        if (label) label.setVisible(visibility);

        const field = byId(id);
        field.setVisible(visibility);
      };

      const setFileEndings = function (fileEndings) {
        console.log('File Endings:', fileEndings);
        const oFileUploader = byId('uploader');
        if (fileEndings) {
          const fileTypes = fileEndings.split(',').map(function (sFileEnding) {
            return sFileEnding.trim();
          });
          console.log('File types:', fileTypes);
          oFileUploader.setFileType(fileTypes);
        } else {
          oFileUploader.setFileType([]);
        }
      };

      const onChange = function (oEvent) {
        // Get Value
        const showSystemId = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().reqSystemId;
        setFieldVisibility('systemId', showSystemId);

        const showDefaultRating = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().defaultRating;
        setFieldVisibility('defaultRating', showDefaultRating);

        const showComment = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().comment;
        setFieldVisibility('comment', showComment);

        const showOverwrite = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().overwrite;
        setFieldVisibility('overwrite', showOverwrite);

        const fileEndings = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().fileEndings;
        setFileEndings(fileEndings);

        isFileUploadRequired = !!fileEndings;

        // If no file endings are defined => No File Uplaod required (e.g. BTP Connector)
        setFieldVisibility('uploader', isFileUploadRequired);
        setOkButtonEnabled(!isFileUploadRequired);

        const description = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().description;
        const oDesription = byId('importDescription');
        oDesription.setText(description);
      };

      return {
        onChange,
        onBeforeOpen: function (oEvent) {
          oImportDialog = oEvent.getSource();
          oExtensionAPI.addDependent(oImportDialog);

          setFieldVisibility('systemId', false);
          setFieldVisibility('defaultRating', false);
          setFieldVisibility('overwrite', false);
          setFieldVisibility('comment', false);
          setFieldVisibility('uploader', false);
          setFileEndings('');
        },

        onAfterClose: function (oEvent) {
          oExtensionAPI.removeDependent(oImportDialog);
          oImportDialog.destroy();
          oImportDialog = undefined;
        },

        onOk: async function (oEvent) {
          setDialogBusy(true);

          if (!isFileUploadRequired) {
            await oExtensionAPI.getEditFlow().invokeAction('triggerImport', {
              model: oExtensionAPI.getModel(),
              parameterValues: [
                {
                  name: 'importType',
                  value: byId('importType').getSelectedKey()
                },
                { name: 'systemId', value: byId('systemId').getSelectedKey() }
              ],
              skipParameterDialog: true
            });
            oExtensionAPI.refresh();
            setDialogBusy(false);
            closeDialog();
            return;
          }
          const oFileUploader = byId('uploader');
          const serviceUrl =
            oExtensionAPI.getModel().getServiceUrl() + 'FileUpload/file';

          oFileUploader.setUploadUrl(serviceUrl);
          oFileUploader.destroyHeaderParameters();

          const xCrsrfToken = new FileUploaderParameter();
          xCrsrfToken.setName('X-CSRF-Token');
          xCrsrfToken.setValue(
            oExtensionAPI.getModel().getHttpHeaders()['X-CSRF-Token']
          );
          oFileUploader.addHeaderParameter(xCrsrfToken);

          const uploadType = new FileUploaderParameter();
          uploadType.setName('X-Upload-Type');
          uploadType.setValue(byId('importType').getSelectedKey());
          oFileUploader.addHeaderParameter(uploadType);

          const fileName = new FileUploaderParameter();
          fileName.setName('X-File-Name');
          fileName.setValue(oFileUploader.getValue());
          oFileUploader.addHeaderParameter(fileName);

          const systemId = new FileUploaderParameter();
          systemId.setName('X-System-Id');
          systemId.setValue(byId('systemId').getSelectedKey());
          oFileUploader.addHeaderParameter(systemId);

          const defaultRating = new FileUploaderParameter();
          defaultRating.setName('X-Default-Rating');
          defaultRating.setValue(byId('defaultRating').getSelectedKey());
          oFileUploader.addHeaderParameter(defaultRating);

          const overwrite = new FileUploaderParameter();
          overwrite.setName('X-Overwrite');
          overwrite.setValue(byId('overwrite').getSelected());
          oFileUploader.addHeaderParameter(overwrite);

          const comment = new FileUploaderParameter();
          comment.setName('X-Comment');
          comment.setValue(byId('comment').getValue());
          oFileUploader.addHeaderParameter(comment);

          oFileUploader
            .checkFileReadable()
            .then(function () {
              oFileUploader.upload();
            })
            .catch(function (error) {
              showError('The file cannot be read.');
              setDialogBusy(false);
            });
        },

        onCancel: function (oEvent) {
          closeDialog();
        },

        onTypeMismatch: function (oEvent) {
          const sSupportedFileTypes = oEvent
            .getSource()
            .getFileType()
            .map(function (sFileType) {
              return '*.' + sFileType;
            })
            .join(', ');

          showError(
            'The file type *.' +
              oEvent.getParameter('fileType') +
              ' is not supported. Choose one of the following types: ' +
              sSupportedFileTypes
          );
        },

        onFileAllowed: function (oEvent) {
          setOkButtonEnabled(true);
        },

        onFileEmpty: function (oEvent) {
          setOkButtonEnabled(false);
        },

        onUploadComplete: function (oEvent) {
          const iStatus = oEvent.getParameter('status');
          const oFileUploader = oEvent.getSource();

          oFileUploader.clear();
          setOkButtonEnabled(false);
          setDialogBusy(false);

          if (iStatus >= 400) {
            const oRawResponse = JSON.parse(oEvent.getParameter('responseRaw'));
            showError(
              oRawResponse && oRawResponse.error && oRawResponse.error.message
            );
          } else {
            MessageToast.show('Uploaded successfully');
            oExtensionAPI.refresh();
            closeDialog();
          }
        }
      };
    };

    const _createExportController = (oExtensionAPI) => {
      let oExportDialog;

      const setOkButtonEnabled = function (bOk) {
        oExportDialog && oExportDialog.getBeginButton().setEnabled(bOk);
      };

      const setDialogBusy = function (bBusy) {
        oExportDialog.setBusy(bBusy);
      };

      const closeDialog = function () {
        oExportDialog && oExportDialog.close();
      };

      const showError = function (sMessage) {
        MessageBox.error(sMessage || 'Export failed');
      };

      const byId = function (sId) {
        return sap.ui.core.Fragment.byId('exportDialog', sId);
      };

      const setFieldVisibility = function (id, visibility) {
        const label = byId('label' + id.charAt(0).toUpperCase() + id.slice(1));
        if (label) label.setVisible(visibility);

        const field = byId(id);
        field.setVisible(visibility);
      };

      const onChange = function (oEvent) {
        // Get Value
        const showLegacy = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().legacy;
        setFieldVisibility('legacy', showLegacy);

        const description = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().description;
        const oDesription = byId('exportDescription');
        oDesription.setText(description);

        const showDateFrom = oEvent
          .getParameter('selectedItem')
          .getBindingContext()
          .getObject().dateFrom;
        setFieldVisibility('dateFrom', showDateFrom);

        setOkButtonEnabled(true);
      };

      return {
        onChange,
        onBeforeOpen: function (oEvent) {
          oExportDialog = oEvent.getSource();
          oExtensionAPI.addDependent(oExportDialog);

          setFieldVisibility('legacy', false);
          setFieldVisibility('dateFrom', false);
        },

        onAfterClose: function (oEvent) {
          oExtensionAPI.removeDependent(oExportDialog);
          oExportDialog.destroy();
          oExportDialog = undefined;
        },

        onOk: async function (oEvent) {
          setDialogBusy(true);
          let dateValue = byId('dateFrom').getDateValue();
          if (!dateValue) {
            dateValue = null;
          }

          await oExtensionAPI.getEditFlow().invokeAction('triggerExport', {
            model: oExtensionAPI.getModel(),
            parameterValues: [
              {
                name: 'exportType',
                value: byId('exportType').getSelectedKey()
              },
              { name: 'legacy', value: byId('legacy').getSelected() },
              { name: 'dateFrom', value: dateValue }
            ],
            skipParameterDialog: true
          });
          oExtensionAPI.refresh();
          setDialogBusy(false);
          closeDialog();
        },

        onCancel: function (oEvent) {
          closeDialog();
        }
      };
    };

    return {
      showImportDialog: function (oEvent) {
        this.loadFragment({
          id: 'importDialog',
          name: 'monitorjob.ext.fragment.ImportDialog',
          controller: _createImportController(this)
        }).then(function (oDialog) {
          oDialog.open();
        });
      },
      showExportDialog: function (oEvent) {
        this.loadFragment({
          id: 'exportDialog',
          name: 'monitorjob.ext.fragment.ExportDialog',
          controller: _createExportController(this)
        }).then(function (oDialog) {
          oDialog.open();
        });
      }
    };
  }
);
