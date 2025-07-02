import PropTypes from 'prop-types';
import { PureComponent } from 'react';

import { FormattedMessage } from 'react-intl';

import { connect } from 'react-redux';

import { expandCommunityTimeline } from 'mastodon/actions/timelines';
import StatusList from 'mastodon/components/status_list';

import { List as ImmutableList } from 'immutable';

const mapStateToProps = state => ({
  statusIds: state.getIn(['timelines', 'community', 'items'], ImmutableList()),
  isLoading: state.getIn(['timelines', 'community', 'isLoading'], true),
  hasMore: state.getIn(['timelines', 'community', 'hasMore'], false),
});

class EmptyHomeTimeline extends PureComponent {
  static propTypes = {
    dispatch: PropTypes.func.isRequired,
    statusIds: PropTypes.object,
    isLoading: PropTypes.bool,
    hasMore: PropTypes.bool,
    multiColumn: PropTypes.bool,
  };

  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(expandCommunityTimeline());
  }

  handleLoadMore = maxId => {
    const { dispatch } = this.props;
    dispatch(expandCommunityTimeline({ maxId }));
  };

  render() {
    const { statusIds, isLoading, hasMore, multiColumn } = this.props;

    const emptyMessage = (
      <FormattedMessage
        id='empty_column.community'
        defaultMessage='The local timeline is empty. Write something publicly to get the ball rolling!'
      />
    );

    return (
      <StatusList
        trackScroll={false}
        scrollKey='empty_home_timeline'
        statusIds={statusIds}
        onLoadMore={this.handleLoadMore}
        timelineId='community'
        emptyMessage={emptyMessage}
        isLoading={isLoading}
        hasMore={hasMore}
        bindToDocument={!multiColumn}
      />
    );
  }
}

export default connect(mapStateToProps)(EmptyHomeTimeline);