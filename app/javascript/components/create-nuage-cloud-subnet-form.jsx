import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import NuageCloudSubnetForm from './forms/nuage-cloud-subnet-form'
import { handleApiError, createSubnet, fetchRouter } from '../utils/api.js'

class CreateNuageCloudSubnetForm extends React.Component {
  constructor(props) {
    super(props);
    this.handleFormStateUpdate = this.handleFormStateUpdate.bind(this);
    this.state = {
      loading: true
    }
  }

  componentDidMount() {
    this.props.dispatch({
      type: 'FormButtons.init',
      payload: {
        newRecord: true,
        pristine: true,
        addClicked: () => createSubnet(this.state.values, this.state.emsId, this.state.routerRef)
      }
    });
    fetchRouter(ManageIQ.record.recordId).then(router => {
      this.setState({emsId: router.ems_id, routerRef: router.ems_ref, loading: false});
    }, handleApiError(this));
  }

  handleFormStateUpdate(formState) {
    this.props.dispatch({ type: 'FormButtons.saveable', payload: formState.valid });
    this.props.dispatch({ type: 'FormButtons.pristine', payload: formState.pristine });
    this.setState({ values: formState.values });
  }

  render() {
    if(this.state.error) {
      return <p>{this.state.error}</p>
    }
    return (
      <NuageCloudSubnetForm
        updateFormState={this.handleFormStateUpdate}
        loading={this.state.loading}
      />
    );
  }
}

CreateNuageCloudSubnetForm.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(CreateNuageCloudSubnetForm);
