import { addValidator } from 'redux-form-validators';

export const ip4Validator = addValidator({
  defaultMessage: __('Must be IPv4 address'),
  validator: function(options, value, allValues) {
    return (/^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/).test(value)
  }
});

export const netmaskValidator = addValidator({
  defaultMessage: __('Must be netmask'),
  validator: function(options, value, allValues) {
    return (/^(((128|192|224|240|248|252|254)\.0\.0\.0)|(255\.(0|128|192|224|240|248|252|254)\.0\.0)|(255\.255\.(0|128|192|224|240|248|252|254)\.0)|(255\.255\.255\.(0|128|192|224|240|248|252|254)))$/).test(value)
  }
});
