import PropTypes from 'prop-types';

import { FormattedMessage } from 'react-intl';

import ImmutablePropTypes from 'react-immutable-proptypes';
import ImmutablePureComponent from 'react-immutable-pure-component';
import { connect } from 'react-redux';

import { normalizeForLookup } from 'mastodon/reducers/accounts_map';
import { expandAccountFeaturedTimeline } from 'mastodon/actions/timelines';
import { ColumnBackButton } from 'mastodon/components/column_back_button';
import StatusList from 'mastodon/components/status_list';
import Column from 'mastodon/features/ui/components/column';
import { AccountHeader } from '../account_timeline/components/account_header';
import { LimitedAccountHint } from '../account_timeline/components/limited_account_hint';
import BundleColumnError from '../ui/components/bundle_column_error';
import { getStatusList } from 'mastodon/selectors';
import { List as ImmutableList } from 'immutable';

const emptyList = ImmutableList();

const mapStateToProps = (state, { params: { acct, id } }) => {
  const accountId = id || state.accounts_map[normalizeForLookup(acct)];

  if (accountId === null) {
    return {
      isLoading: false,
      isAccount: false,
      statusIds: emptyList,
    };
  } else if (!accountId) {
    return {
      isLoading: true,
      statusIds: emptyList,
    };
  }

  return {
    accountId,
    isAccount: !!state.getIn(['accounts', accountId]),
    statusIds: state.getIn(['timelines', `account:${accountId}:pinned`, 'items'], emptyList),
    isLoading: state.getIn(['timelines', `account:${accountId}:pinned`, 'isLoading']),
    hasMore: state.getIn(['timelines', `account:${accountId}:pinned`, 'hasMore']),
    suspended: state.getIn(['accounts', accountId, 'suspended'], false),
    hidden: state.getIn(['accounts', accountId, 'hidden'], false),
    blockedBy: state.getIn(['relationships', accountId, 'blocked_by'], false),
  };
};

class AccountShowcase extends ImmutablePureComponent {

  static propTypes = {
    params: PropTypes.shape({
      acct: PropTypes.string,
      id: PropTypes.string,
    }).isRequired,
    dispatch: PropTypes.func.isRequired,
    accountId: PropTypes.string,
    statusIds: ImmutablePropTypes.list,
    isLoading: PropTypes.bool,
    hasMore: PropTypes.bool,
    isAccount: PropTypes.bool,
    suspended: PropTypes.bool,
    hidden: PropTypes.bool,
    blockedBy: PropTypes.bool,
    multiColumn: PropTypes.bool,
  };

  componentDidMount () {
    const { accountId, dispatch } = this.props;
    if (accountId && accountId !== -1) {
      dispatch(expandAccountFeaturedTimeline(accountId));
    }
  }

  componentDidUpdate (prevProps) {
    const { accountId, dispatch } = this.props;
    if (accountId && accountId !== -1 && accountId !== prevProps.accountId) {
      dispatch(expandAccountFeaturedTimeline(accountId));
    }
  }

  handleLoadMore = maxId => {
    const { accountId, dispatch } = this.props;
    if (accountId && accountId !== -1) {
      dispatch(expandAccountFeaturedTimeline(accountId, { maxId }));
    }
  };

  render () {
    const { accountId, statusIds, isLoading, hasMore, isAccount, suspended, hidden, blockedBy, multiColumn } = this.props;

    if (accountId === null) {
      return (
        <BundleColumnError multiColumn={multiColumn} errorType='routing' />
      );
    } else if (!accountId) {
      return (
        <Column>
          <ColumnBackButton />
          <div className='empty-column-indicator'>
            <FormattedMessage id='missing_indicator.label' defaultMessage='Not found' />
          </div>
        </Column>
      );
    }

    let emptyMessage;
    const forceEmptyState = suspended || blockedBy || hidden;

    if (suspended) {
      emptyMessage = <FormattedMessage id='empty_column.account_suspended' defaultMessage='Account suspended' />;
    } else if (hidden) {
      emptyMessage = <LimitedAccountHint accountId={accountId} />;
    } else if (blockedBy) {
      emptyMessage = <FormattedMessage id='empty_column.account_unavailable' defaultMessage='Profile unavailable' />;
    } else {
      emptyMessage = <FormattedMessage id='empty_column.account_showcase' defaultMessage='No showcase items. Pin some posts to your profile to see them here!' />;
    }

    return (
      <Column>
        <ColumnBackButton />
        <StatusList
          prepend={
            <AccountHeader accountId={accountId} hideTabs={forceEmptyState} />
          }
          alwaysPrepend
          statusIds={forceEmptyState ? emptyList : statusIds}
          scrollKey='account_showcase'
          hasMore={!forceEmptyState && hasMore}
          isLoading={isLoading}
          onLoadMore={this.handleLoadMore}
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
          timelineId='showcase'
        />
      </Column>
    );
  }

}

export default connect(mapStateToProps)(AccountShowcase);