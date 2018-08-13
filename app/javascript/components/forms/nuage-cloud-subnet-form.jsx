import React, { Component } from 'react';
import { Form, Field, FormSpy } from 'react-final-form';
import { Form as PfForm, Grid, Button, Col, Row, Spinner } from 'patternfly-react';
import PropTypes from 'prop-types';
import { required } from 'redux-form-validators';

import { FinalFormField, FinalFormTextArea, FinalFormSelect } from '@manageiq/react-ui-components/dist/forms';
import { ip4Validator, netmaskValidator } from '../../utils/validators'

const NuageCloudSubnetForm = ({loading, updateFormState}) => {
  if(loading){
    return (
      <Spinner loading size="lg" />
    );
  }

  return (
    <Form
      onSubmit={() => {}} // handled by modal
      render={({ handleSubmit }) => (
        <PfForm horizontal>
          <FormSpy onChange={state => updateFormState({ ...state, values: state.values })} />
          <Grid fluid>
            <Row>
              <Col xs={12}>
                <Field
                  name="name"
                  component={FinalFormField}
                  label={__('Name')}
                  placeholder="Subnet Name"
                  validate={required({ msg: 'Name is required' })}
                />
              </Col>
              <Col xs={12}>
                <Field
                  name="address"
                  component={FinalFormField}
                  label={__('Address')}
                  placeholder="100.100.100.0"
                  validate={ip4Validator()}
                />
              </Col>
              <Col xs={12}>
                <Field
                  name="netmask"
                  component={FinalFormField}
                  label={__('Netmask')}
                  placeholder="255.255.255.0"
                  validate={netmaskValidator()}
                />
              </Col>
              <Col xs={12}>
                <Field
                  name="gateway"
                  component={FinalFormField}
                  label={__('Gateway')}
                  placeholder="100.100.100.1"
                  validate={ip4Validator()}
                />
              </Col>
              <hr />
            </Row>
          </Grid>
        </PfForm>
      )}
    />
  );
};

NuageCloudSubnetForm.propTypes = {
  updateFormState: PropTypes.func.isRequired,
  loading: PropTypes.bool
};

NuageCloudSubnetForm.defaultProps = {
  loading: false,
};

export default NuageCloudSubnetForm;
