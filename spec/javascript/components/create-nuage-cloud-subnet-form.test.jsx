import CreateNuageCloudSubnetForm from '../../../app/javascript/components/create-nuage-cloud-subnet-form'
import * as api from "../../../app/javascript/utils/api";

const fetchRouterMock = jest.spyOn(api, 'fetchRouter').mockResolvedValue('SUCCESS');
const dispatchMock = jest.spyOn(DEFAULT_STORE, 'dispatch');

let renderComponent;
let renderComponentFull;

describe('CreateNuageCloudSubnetForm', () => {
  beforeAll(() => {
    renderComponent = () => shallowRedux(<CreateNuageCloudSubnetForm />);
    renderComponentFull = () => mountRedux(<CreateNuageCloudSubnetForm />);
  });

  beforeEach(() => {
    ManageIQ.record.recordId = 123;
  });

  describe('componentDidMount', () => {
    it('router fetch succeeds', () => {
      fetchRouterMock.mockResolvedValue({ ems_id: 111, ems_ref: 222 });
      let component = renderComponent();
      return fetchRouterMock().then(() => {
        component.update();
        expect(fetchRouterMock).toHaveBeenCalledWith(123);
        expect(component.state()).toEqual({emsId: 111, routerRef: 222, loading: false});
        expect(toJson(component)).toMatchSnapshot();
      });
    });

    it('router fetch fails', () => {
      fetchRouterMock.mockRejectedValue({data: {error: { message: 'MSG'}}});
      let component = renderComponent();
      return fetchRouterMock().catch(() => {
        component.update();
        expect(fetchRouterMock).toHaveBeenCalledWith(123);
        expect(component.state()).toEqual({loading: false, error: 'MSG'});
        expect(toJson(component)).toMatchSnapshot();
      });
    });
  });

  describe('redux bindings', () => {
    it('when fully mounted', () => {
      fetchRouterMock.mockResolvedValue('SUCCESS');
      let component = renderComponentFull();
      return fetchRouterMock().then(() => {
        expect(dispatchMock).toHaveBeenCalledWith({type: 'FormButtons.init',     payload: expect.anything()});
        expect(dispatchMock).toHaveBeenCalledWith({type: 'FormButtons.saveable', payload: expect.anything()});
        expect(dispatchMock).toHaveBeenCalledWith({type: 'FormButtons.pristine', payload: expect.anything()});
      });
    });
  });
});
