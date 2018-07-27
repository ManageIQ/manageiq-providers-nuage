import NuageCloudSubnetForm from '../../../../app/javascript/components/forms/nuage-cloud-subnet-form'

let renderComponent;

describe('NuageCloudSubnetForm', () => {
  beforeAll(() => {
    renderComponent = (loading = false) => shallowRedux(<NuageCloudSubnetForm updateFormState={jest.fn()} loading={loading} />);
  });

  describe('renders', () => {
    it('form', () => {
      let component = renderComponent();
      expect(toJson(component)).toMatchSnapshot();
    });

    it('spinner', () => {
      let component = renderComponent(true);
      expect(toJson(component)).toMatchSnapshot();
    });
  });
});
