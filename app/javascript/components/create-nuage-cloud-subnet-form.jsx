import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import MiqFormRenderer from '@@ddf';

import createSchema from './create-nuage-cloud-subnet-form.schema';

const CreateNuageCloudSubnetForm = ({ dispatch }) => {
  const initialize = (formOptions) => {
    dispatch({
      type: 'FormButtons.init',
      payload: {
        newRecord: true,
        pristine: true,
      },
    });

    dispatch({
      type: 'FormButtons.callbacks',
      payload: { addClicked: () => formOptions.submit() },
    });
  });

  const submitValues = (values) => {
    API.get(`/api/network_routers/${ManageIQ.record.recordId}?attributes=ems_ref,name,ems_id`).then(({ ems_ref: router_ref, ems_id }) =>
      API.post(`/api/providers/${ems_id}/cloud_subnets`, {
        action: "create",
        resource: { ...values, router_ref },
      }).then(({ results }) =>
        results.forEach((res) => window.add_flash(res.message, res.success ? "success" : "error"))
      )
    ).catch((err) => {
      window.add_flash(err.data && err.data.error && err.data.error.message || __('Unknown API error'), "error");
    });
  };

  return (
    <MiqFormRenderer
      schema={createSchema()}
      onSubmit={submitValues}
      showFormControls={false}
      onStateUpdate={handleFormStateUpdate}
      initialize={initialize}
    />
  )
};

CreateNuageCloudSubnetForm.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(CreateNuageCloudSubnetForm);
