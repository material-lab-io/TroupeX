import Column from '../ui/components/column';

const Messages: React.FC<{ multiColumn?: boolean }> = ({ multiColumn }) => {
  return (
    <Column>
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100%',
        minHeight: '400px'
      }}>
        <h1 style={{
          fontSize: '48px',
          fontWeight: '700',
          color: 'var(--primary-text-color)',
          marginBottom: '16px'
        }}>Coming Soon</h1>
        <p style={{
          fontSize: '18px',
          color: 'var(--secondary-text-color)'
        }}>Messages feature is under development</p>
      </div>
    </Column>
  );
};

export default Messages;