import { useCallback, useState, useEffect } from 'react';

import { defineMessages, useIntl, FormattedMessage } from 'react-intl';

import { Icon } from '@/mastodon/components/icon';
import { IconButton } from '@/mastodon/components/icon_button';
import type { PersonaType } from '@/mastodon/components/persona_profile_display';
import AddIcon from '@/material-icons/400-24px/add.svg?react';
import DeleteIcon from '@/material-icons/400-24px/delete.svg?react';
import EditIcon from '@/material-icons/400-24px/edit.svg?react';
import MovieIcon from '@/material-icons/400-24px/movie.svg?react';
import PhotoCameraIcon from '@/material-icons/400-24px/photo_camera.svg?react';
import SettingsIcon from '@/material-icons/400-24px/settings.svg?react';


const messages = defineMessages({
  roleLabel: { id: 'persona.role_label', defaultMessage: 'Professional Role' },
  personaLabel: { id: 'persona.persona_label', defaultMessage: 'Industry Category' },
  creditsLabel: { id: 'persona.credits_label', defaultMessage: 'Projects & Credits' },
  oneDayLabel: { id: 'persona.one_day_label', defaultMessage: 'One Day...' },
  dreamLabel: { id: 'persona.dream_label', defaultMessage: 'My Dream' },
  favoritesLabel: { id: 'persona.favorites_label', defaultMessage: 'Favorites & Inspirations' },
  addCredit: { id: 'persona.add_credit', defaultMessage: 'Add Project' },
  addFavorite: { id: 'persona.add_favorite', defaultMessage: 'Add Favorite' },
  deleteCredit: { id: 'persona.delete_credit', defaultMessage: 'Remove Project' },
  deleteFavorite: { id: 'persona.delete_favorite', defaultMessage: 'Remove Favorite' },
  projectPlaceholder: { id: 'persona.project_placeholder', defaultMessage: 'Project Name' },
  yearPlaceholder: { id: 'persona.year_placeholder', defaultMessage: 'Year' },
  rolePlaceholder: { id: 'persona.role_placeholder', defaultMessage: 'Your Role' },
  favoritePlaceholder: { id: 'persona.favorite_placeholder', defaultMessage: 'Add an inspiration...' },
  carouselPhotosLabel: { id: 'persona.carousel_photos_label', defaultMessage: 'Profile Photos' },
  carouselPhotosHint: { id: 'persona.carousel_photos_hint', defaultMessage: 'Add multiple photos for your profile carousel' },
  addPhoto: { id: 'persona.add_photo', defaultMessage: 'Add Photo' },
});

interface PersonaOption {
  value: PersonaType;
  label: string;
  icon: React.ComponentType;
  roles: string[];
}

const PERSONA_OPTIONS: PersonaOption[] = [
  {
    value: 'creative',
    label: 'Creative',
    icon: EditIcon,
    roles: ['Actor', 'Artist', 'Writer', 'Composer', 'Choreographer', 'Musician', 'Singer', 'Dancer'],
  },
  {
    value: 'technical',
    label: 'Technical',
    icon: PhotoCameraIcon,
    roles: ['Cinematographer', 'Lighting Expert', 'VFX Artist', 'Camera Operator', 'Gaffer', 'Sound Engineer', 'Colorist'],
  },
  {
    value: 'production',
    label: 'Production',
    icon: MovieIcon,
    roles: ['Director', 'Producer', 'Assistant Director', 'Production Manager', 'Casting Director', 'Script Supervisor'],
  },
  {
    value: 'support',
    label: 'Support',
    icon: SettingsIcon,
    roles: ['Editor', 'Sound Designer', 'Makeup Artist', 'Costume Designer', 'Set Designer', 'Props Master', 'Hair Stylist'],
  },
];

interface Credit {
  project: string;
  year?: string;
  role?: string;
}

export const PersonaProfileEditor: React.FC = () => {
  const intl = useIntl();
  const [persona, setPersona] = useState<PersonaType>('creative');
  const [role, setRole] = useState('');
  const [credits, setCredits] = useState<Credit[]>([{ project: '', year: '', role: '' }]);
  const [oneDay, setOneDay] = useState('');
  const [dream, setDream] = useState('');
  const [favorites, setFavorites] = useState<string[]>(['']);
  const [carouselPhotos, setCarouselPhotos] = useState<string[]>([]);

  // Load existing data from hidden form fields on mount
  useEffect(() => {
    const fields = document.querySelectorAll<HTMLInputElement>('input[name*="[fields_attributes]"]');
    fields.forEach((field) => {
      if (field.name.includes('[name]')) {
        const valueField = field.parentElement?.querySelector<HTMLInputElement>('input[name*="[value]"]');
        if (valueField) {
          const fieldName = field.value.toLowerCase();
          const fieldValue = valueField.value;
          
          switch (fieldName) {
            case 'role':
            case 'profession':
              setRole(fieldValue);
              // Auto-detect persona from role
              for (const option of PERSONA_OPTIONS) {
                if (option.roles.some(r => fieldValue.toLowerCase().includes(r.toLowerCase()))) {
                  setPersona(option.value);
                  break;
                }
              }
              break;
            case 'credits':
            case 'projects':
              try {
                const parsed = JSON.parse(fieldValue) as unknown;
                if (Array.isArray(parsed)) {
                  setCredits(parsed as Credit[]);
                }
              } catch {}
              break;
            case 'one day':
            case 'oneday':
              setOneDay(fieldValue);
              break;
            case 'dream':
              setDream(fieldValue);
              break;
            case 'favorites':
            case 'inspirations':
              try {
                const parsed = JSON.parse(fieldValue) as unknown;
                if (Array.isArray(parsed)) {
                  setFavorites(parsed as string[]);
                }
              } catch {}
              break;
            case 'carousel_photos':
              try {
                const parsed = JSON.parse(fieldValue) as unknown;
                if (Array.isArray(parsed)) {
                  setCarouselPhotos(parsed as string[]);
                }
              } catch {}
              break;
          }
        }
      }
    });
  }, []);

  // Update hidden form fields when data changes
  const updateFormFields = useCallback(() => {
    const fieldsData = [
      { name: 'Role', value: role },
      { name: 'Credits', value: JSON.stringify(credits.filter(c => c.project)) },
      { name: 'One Day', value: oneDay },
      { name: 'Dream', value: dream },
      { name: 'Favorites', value: JSON.stringify(favorites.filter(Boolean)) },
      { name: 'carousel_photos', value: JSON.stringify(carouselPhotos) },
    ];

    // Update existing fields or create new ones
    fieldsData.forEach((data, index) => {
      const nameField = document.querySelector<HTMLInputElement>(`input[name="account[fields_attributes][${index}][name]"]`);
      const valueField = document.querySelector<HTMLInputElement>(`input[name="account[fields_attributes][${index}][value]"]`);
      
      if (nameField && valueField) {
        nameField.value = data.name;
        valueField.value = data.value;
      }
    });
  }, [role, credits, oneDay, dream, favorites, carouselPhotos]);

  useEffect(() => {
    updateFormFields();
  }, [updateFormFields]);

  const handlePersonaChange = useCallback((newPersona: PersonaType) => {
    setPersona(newPersona);
  }, []);

  const handleCreditChange = useCallback((index: number, field: keyof Credit, value: string) => {
    const newCredits = [...credits];
    const updatedCredit = { ...newCredits[index] };
    if (field === 'project') {
      updatedCredit.project = value;
    } else if (field === 'year') {
      updatedCredit.year = value;
    } else if (field === 'role') {
      updatedCredit.role = value;
    }
    newCredits[index] = updatedCredit;
    setCredits(newCredits);
  }, [credits]);

  const addCredit = useCallback(() => {
    setCredits([...credits, { project: '', year: '', role: '' }]);
  }, [credits]);

  const removeCredit = useCallback((index: number) => {
    setCredits(credits.filter((_, i) => i !== index));
  }, [credits]);

  const handleFavoriteChange = useCallback((index: number, value: string) => {
    const newFavorites = [...favorites];
    newFavorites[index] = value;
    setFavorites(newFavorites);
  }, [favorites]);

  const addFavorite = useCallback(() => {
    setFavorites([...favorites, '']);
  }, [favorites]);

  const removeFavorite = useCallback((index: number) => {
    setFavorites(favorites.filter((_, i) => i !== index));
  }, [favorites]);

  const selectedPersona = PERSONA_OPTIONS.find(p => p.value === persona) ?? PERSONA_OPTIONS[0];
  // const PersonaIcon = selectedPersona.icon; // Unused variable

  return (
    <div className='persona-profile-editor'>
      <h4 className='persona-profile-editor__section-title'>
        <FormattedMessage id='persona.professional_profile' defaultMessage='Professional Profile' />
      </h4>

      <div className='persona-profile-editor__personas'>
        <label className='persona-profile-editor__label'>
          {intl.formatMessage(messages.personaLabel)}
        </label>
        <div className='persona-profile-editor__persona-grid'>
          {PERSONA_OPTIONS.map(option => (
            <button
              key={option.value}
              type='button'
              className={`persona-profile-editor__persona-option ${persona === option.value ? 'active' : ''}`}
              onClick={() => { handlePersonaChange(option.value); }}
            >
              <Icon id={option.value} icon={option.icon as any} />
              <span>{option.label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className='persona-profile-editor__field'>
        <label className='persona-profile-editor__label'>
          {intl.formatMessage(messages.roleLabel)}
        </label>
        <select
          className='persona-profile-editor__select'
          value={role}
          onChange={(e) => { setRole(e.target.value); }}
        >
          <option value=''>Select your role...</option>
          {selectedPersona.roles.map(r => (
            <option key={r} value={r}>{r}</option>
          ))}
        </select>
      </div>

      <div className='persona-profile-editor__field'>
        <label className='persona-profile-editor__label'>
          {intl.formatMessage(messages.creditsLabel)}
        </label>
        <div className='persona-profile-editor__credits'>
          {credits.map((credit, index) => (
            <div key={index} className='persona-profile-editor__credit'>
              <input
                type='text'
                placeholder={intl.formatMessage(messages.projectPlaceholder)}
                value={credit.project}
                onChange={(e) => { handleCreditChange(index, 'project', e.target.value); }}
                className='persona-profile-editor__input'
              />
              <input
                type='text'
                placeholder={intl.formatMessage(messages.yearPlaceholder)}
                value={credit.year || ''}
                onChange={(e) => { handleCreditChange(index, 'year', e.target.value); }}
                className='persona-profile-editor__input persona-profile-editor__input--small'
              />
              <input
                type='text'
                placeholder={intl.formatMessage(messages.rolePlaceholder)}
                value={credit.role || ''}
                onChange={(e) => { handleCreditChange(index, 'role', e.target.value); }}
                className='persona-profile-editor__input'
              />
              <IconButton
                icon='delete'
                iconComponent={DeleteIcon}
                title={intl.formatMessage(messages.deleteCredit)}
                onClick={() => { removeCredit(index); }}
                disabled={credits.length === 1}
              />
            </div>
          ))}
          <button
            type='button'
            className='persona-profile-editor__add-button'
            onClick={addCredit}
          >
            <Icon id='add' icon={AddIcon} />
            {intl.formatMessage(messages.addCredit)}
          </button>
        </div>
      </div>

      <div className='persona-profile-editor__field'>
        <label className='persona-profile-editor__label'>
          {intl.formatMessage(messages.oneDayLabel)}
        </label>
        <textarea
          className='persona-profile-editor__textarea'
          value={oneDay}
          onChange={(e) => { setOneDay(e.target.value); }}
          placeholder='What do you aspire to achieve one day?'
          rows={2}
        />
      </div>

      <div className='persona-profile-editor__field'>
        <label className='persona-profile-editor__label'>
          {intl.formatMessage(messages.dreamLabel)}
        </label>
        <textarea
          className='persona-profile-editor__textarea'
          value={dream}
          onChange={(e) => { setDream(e.target.value); }}
          placeholder='What is your ultimate dream?'
          rows={2}
        />
      </div>

      <div className='persona-profile-editor__field'>
        <label className='persona-profile-editor__label'>
          {intl.formatMessage(messages.favoritesLabel)}
        </label>
        <div className='persona-profile-editor__favorites'>
          {favorites.map((favorite, index) => (
            <div key={index} className='persona-profile-editor__favorite'>
              <input
                type='text'
                placeholder={intl.formatMessage(messages.favoritePlaceholder)}
                value={favorite}
                onChange={(e) => { handleFavoriteChange(index, e.target.value); }}
                className='persona-profile-editor__input'
              />
              <IconButton
                icon='delete'
                iconComponent={DeleteIcon}
                title={intl.formatMessage(messages.deleteFavorite)}
                onClick={() => { removeFavorite(index); }}
                disabled={favorites.length === 1}
              />
            </div>
          ))}
          <button
            type='button'
            className='persona-profile-editor__add-button'
            onClick={addFavorite}
          >
            <Icon id='add' icon={AddIcon} />
            {intl.formatMessage(messages.addFavorite)}
          </button>
        </div>
      </div>
    </div>
  );
};