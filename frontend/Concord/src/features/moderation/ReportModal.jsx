import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '../../components/ui/Button'
import { FormField } from '../../components/ui/FormField'
import { Modal } from '../../components/ui/Modal'
import { Textarea } from '../../components/ui/Textarea'
import { toast } from '../../components/ui/Toast'
import { mapCreateReportError } from './reportsErrors'
import { useCreateReportMutation } from './reportsQueries'

const MAX_REASON_LENGTH = 500

export function ReportModal({ open, onOpenChange, targetType, targetId, title, description }) {
  const { t } = useTranslation()
  const [reason, setReason] = useState('')
  const createReportMutation = useCreateReportMutation()

  const handleOpenChange = (nextOpen) => {
    onOpenChange(nextOpen)
    if (!nextOpen) setReason('')
  }

  const handleSubmit = async () => {
    const trimmed = reason.trim()
    if (!trimmed) return
    try {
      await createReportMutation.mutateAsync({ TargetType: targetType, TargetId: targetId, Reason: trimmed })
      toast({ variant: 'success', title: t('reports.submitted') })
      handleOpenChange(false)
    } catch (error) {
      toast({ variant: 'danger', title: mapCreateReportError(error) })
    }
  }

  return (
    <Modal
      open={open}
      onOpenChange={handleOpenChange}
      title={title}
      description={description}
      footer={
        <>
          <Button variant="ghost" onClick={() => handleOpenChange(false)}>
            {t('common.cancel')}
          </Button>
          <Button
            variant="danger"
            onClick={handleSubmit}
            disabled={!reason.trim() || createReportMutation.isPending}
          >
            {t('reports.submit')}
          </Button>
        </>
      }
    >
      <FormField label={t('reports.reason')} hint={t('reports.reasonHint')}>
        <Textarea
          autoFocus
          value={reason}
          maxLength={MAX_REASON_LENGTH}
          onChange={(event) => setReason(event.target.value)}
        />
      </FormField>
    </Modal>
  )
}
