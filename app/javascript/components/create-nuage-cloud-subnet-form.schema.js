import { componentTypes, validatorTypes } from '@@ddf';

const IPv4 = /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
const mask = /^(((128|192|224|240|248|252|254)\.0\.0\.0)|(255\.(0|128|192|224|240|248|252|254)\.0\.0)|(255\.255\.(0|128|192|224|240|248|252|254)\.0)|(255\.255\.255\.(0|128|192|224|240|248|252|254)))$/;

const createSchema = () => ({
  fields: [
    {
      component: componentTypes.TEXT_FIELD,
      name: 'name',
      label: __('Name'),
      placeholder: __('Subnet Name'),
      isRequired: true,
      validate: [{
        type: validatorTypes.REQUIRED,
        message: __('Required'),
      }],
    },
    {
      component: componentTypes.TEXT_FIELD,
      name: 'address',
      label: __('Address'),
      placeholder: '100.100.100.0',
      isRequired: true,
      validate: [
        {
          type: validatorTypes.REQUIRED,
          message: __('Required'),
        },
        {
          type: validatorTypes.PATTERN,
          pattern: IPv4,
          message: __('Must be a valid IPv4 address'),
        }
      ],
    },
    {
      component: componentTypes.TEXT_FIELD,
      name: 'netmask',
      label: __('Netmask'),
      placeholder: '255.255.255.0',
      isRequired: true,
      validate: [
        {
          type: validatorTypes.REQUIRED,
          message: __('Required'),
        },
        {
          type: validatorTypes.PATTERN,
          pattern: mask,
          message: __('Must be a valid netmask'),
        }
      ],
    },
    {
      component: componentTypes.TEXT_FIELD,
      name: 'gateway',
      label: __('Gateway'),
      placeholder: '100.100.100.1',
      isRequired: true,
      validate: [
        {
          type: validatorTypes.REQUIRED,
          message: __('Required'),
        },
        {
          type: validatorTypes.PATTERN,
          pattern: IPv4,
          message: __('Must be a valid IPv4 address'),
        }
      ],
    },
  ],
});

export default createSchema;
